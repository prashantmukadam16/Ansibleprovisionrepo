# DevOps Project

## Technologies Used

- Jenkins
- Terraform
- Ansible
- Docker
- GCP
- NGINX

## CI/CD Flow

1. Jenkins pulls code from GitHub
2. Terraform provisions infrastructure on GCP
3. Ansible configures servers
4. Docker container deployed
5. NGINX serves application

## Run Terraform

cd terraform/dev

terraform init
terraform apply

## Run Ansible

cd ansible

ansible-playbook -i inventory/dev.ini playbooks/install_nginx.yml
