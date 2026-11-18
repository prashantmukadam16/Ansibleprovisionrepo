# GCP Infrastructure + Ansible Application CI/CD

This repository provisions GCP Compute Engine web VMs with reusable Terraform modules, configures Docker with Ansible, builds the application image on each VM, deploys the container, and runs an HTTP smoke test.

## Architecture and repository layout

```text
.
├── Jenkinsfile
├── app/                         # Docker build context and static web page
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/                # Generated inventory is not committed
│   ├── playbooks/                # Docker setup and application deployment
│   └── roles/docker/             # Reusable Docker installation role
├── scripts/
│   ├── generate_inventory.py     # Terraform output -> Ansible inventory
│   └── smoke_test.py             # HTTP validation against all web VMs
└── terraform/
    ├── dev/                      # Development root module and state config
    ├── prod/                     # Production root module and state config
    └── modules/
        ├── network/              # VPC module
        ├── firewall/             # HTTP + restricted SSH rules
        └── vm/                   # Compute Engine instances
```

## Jenkins prerequisites

Install these on the Jenkins agent (or bake them into its agent image):

- Git, Terraform >= 1.5, Python 3
- Ansible, OpenSSH client
- Google Cloud service-account access to the selected project
- Network connectivity from the Jenkins agent to the VMs over TCP/22 and from the test stage to VM public IPs over TCP/80

Create these Jenkins credentials:

| Credential ID | Jenkins type | Purpose |
|---|---|---|
| `gcp-key` | Secret file | GCP service-account JSON key |
| `gcp-vm-ssh` | SSH Username with private key | SSH access to Ubuntu VMs; username should be `ubuntu` |

The service account needs permissions to manage Compute Engine networks, firewall rules and instances, and to read/write the Terraform state bucket. Prefer a custom least-privilege role for the project. Do not commit service-account keys or SSH private keys.

## One-time GCP setup

1. Confirm the project ID in `terraform/dev/terraform.tfvars` and `terraform/prod/terraform.tfvars`.
2. Create the GCS state buckets before running Jenkins. The Jenkinsfile currently maps `dev` to `terraform-bucketudx-dev` and `prod` to `terraform-state-prod`. Change these names in the Jenkinsfile if your buckets differ. Enable object versioning on both buckets.
3. Replace `203.0.113.10/32` in both tfvars files with the real public egress CIDR of the Jenkins agent and/or administrator workstation. This is a documentation-only IP range and will not permit real SSH access. Never change it to `0.0.0.0/0`.
4. Confirm the production project, region, VM size, instance count, state bucket and SSH allowlist before selecting `prod`.
5. Ensure the Jenkins agent has outbound access to the Google APIs, Ubuntu package repositories, Docker registry and the provisioned VMs.

## Jenkins pipeline flow

The root `Jenkinsfile` implements these ordered stages:

1. **Checkout** — checks out the configured SCM revision.
2. **Tool and Configuration Checks** — verifies Terraform, Ansible, Python, SSH tools, and required project files.
3. **Terraform Format and Validate** — checks formatting and validates the selected environment configuration.
4. **Terraform Plan** — initializes the selected GCS backend, creates a saved plan, and prints the plan for review.
5. **Approve Infrastructure Changes** — pauses for explicit Jenkins approval when `RUN_TERRAFORM_APPLY` is enabled.
6. **Terraform Apply** — applies the exact saved plan and exports Terraform outputs as JSON.
7. **Generate Ansible Inventory** — converts Terraform VM public IP outputs into a temporary Ansible inventory.
8. **Configure Docker Hosts** — runs the Docker setup playbook against all generated web hosts.
9. **Build and Deploy Application** — copies the application, builds its Docker image on target VMs, and starts the container.
10. **Smoke Test** — checks the HTTP response from every generated web host and fails if a host does not return the expected page.

If `RUN_TERRAFORM_APPLY` is disabled, the pipeline performs checkout, checks, validation, and planning only. Approval and all infrastructure/application deployment stages are skipped.

## Configure the Jenkins job

- Prefer a Multibranch Pipeline or Pipeline-from-SCM job pointing to this repository and the `Jenkinsfile` at the repository root.
- Ensure the Jenkins agent has the tools listed above.
- Set the `ENVIRONMENT` build parameter to `dev` first. Use `prod` only after validating its settings.
- Keep `RUN_TERRAFORM_APPLY` enabled for a full deployment. The pipeline always creates a plan, but the apply/deploy stages run only when this parameter is enabled and the manual approval is granted.

## Local Terraform usage (optional)

From `terraform/dev`:

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/secure/path/service-account.json
export TF_VAR_ssh_public_key="$(ssh-keygen -y -f ~/.ssh/id_rsa)"
terraform init -backend-config="bucket=terraform-bucketudx-dev" -backend-config="prefix=terraform/dev"
terraform fmt -check -recursive ..
terraform validate
terraform plan
```

The SSH CIDR list is configured in the environment's `terraform.tfvars`. The SSH public key is intentionally injected at runtime and is not stored in the repository.

## Important operational notes

- Terraform state is stored remotely in GCS; never commit state or plan files.
- Terraform destroy is deliberately not part of this deployment pipeline. Use a separate, separately approved destroy workflow.
- This sample assigns public IPs to the VMs so Ansible and the HTTP smoke test can reach them. For production, prefer private instances with IAP/bastion or a private runner, and expose the application through a load balancer with TLS.
- HTTP ingress is open to the internet on port 80. Add HTTPS/load-balancer design before production use.
- The sample `prod` configuration is a template. Validate it and use a dedicated production project/state bucket and stronger network controls before deployment.
