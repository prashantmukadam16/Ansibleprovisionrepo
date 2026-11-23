pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        timeout(time: 60, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'prod'], description: 'Select the Terraform environment to deploy.')
        booleanParam(name: 'RUN_TERRAFORM_APPLY', defaultValue: true, description: 'When enabled, apply the reviewed plan and run Ansible deployment stages.')
    }

    environment {
        PROJECT_ID = 'project-88c619e6-27a3-4887-94b'
        TF_IN_AUTOMATION = 'true'
        TF_INPUT = 'false'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        ANSIBLE_CONFIG = 'ansible/ansible.cfg'
        APP_IMAGE = 'ansibleprovisionrepo-web:latest'
    }

    stages {
        stage('1. Checkout') {
            steps {
                echo 'Checking out source code from GitHub'

                git branch: 'main',
                    url: 'https://github.com/prashantmukadam16/Ansibleprovisionrepo.git'

                sh '''
                    echo "Git checkout completed"
                    git rev-parse --short HEAD
                    git status --short
                    ls -la
                '''
            }
        }

        stage('2. Tool and Configuration Checks') {
            steps {
                sh '''
                    set -eu
                    for tool in terraform ansible-playbook ansible-inventory python3 ssh-keygen; do
                        command -v "$tool" >/dev/null 2>&1 || {
                            echo "ERROR: required tool is missing: $tool"
                            exit 1
                        }
                    done
                    terraform version
                    ansible --version
                    python3 --version
                    test -f "terraform/${ENVIRONMENT}/main.tf"
                    test -f "terraform/${ENVIRONMENT}/backend.tf"
                    test -f "ansible/playbooks/docker_setup.yml"
                    test -f "ansible/playbooks/deploy_app.yml"
                    test -f "app/Dockerfile"
                    test -f "scripts/generate_inventory.py"
                    test -f "scripts/smoke_test.py"
                '''
            }
        }

        stage('3. Terraform Format and Validate') {
            steps {
                dir("terraform/${params.ENVIRONMENT}") {
                    sh '''
                        set -eu
                        terraform fmt -check -recursive ..
                        terraform init -backend=false
                        terraform validate
                    '''
                }
            }
        }

        stage('4. Terraform Plan') {
            steps {
                withCredentials([
                    file(credentialsId: 'gcp-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS'),
                    sshUserPrivateKey(credentialsId: 'gcp-vm-ssh-verified', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')
                ]) {
                    dir("terraform/${params.ENVIRONMENT}") {
                        sh '''
                            set -eu
                            echo "Validating Jenkins SSH private key..."

                            ssh-keygen -y -f "$SSH_KEY" > /tmp/jenkins_ssh_public_key

                            export TF_VAR_ssh_public_key="$(cat /tmp/jenkins_ssh_public_key)"

                            rm -f /tmp/jenkins_ssh_public_key

                            if [ -z "$TF_VAR_ssh_public_key" ]; then
                                echo "ERROR: SSH public key is empty"
                                exit 1
                            fi

                            echo "SSH private key validation successful."
                            if [ "$ENVIRONMENT" = "dev" ]; then
                                STATE_BUCKET="terraform-bucketudx-dev-426143574253"
                            else
                                STATE_BUCKET="terraform-state-prod"
                            fi
                            terraform init -reconfigure \
                                -backend-config="bucket=${STATE_BUCKET}" \
                                -backend-config="prefix=terraform/${ENVIRONMENT}"
                            terraform plan -input=false -out=tfplan
                            terraform show -no-color tfplan
                        '''
                    }
                }
            }
        }

        stage('5. Approve Infrastructure Changes') {
            when { expression { return params.RUN_TERRAFORM_APPLY } }
            steps {
                script {
                    input(
                        message: "Review the Terraform plan in the build log. Apply changes to ${params.ENVIRONMENT.toUpperCase()}?",
                        ok: 'Approve and Apply'
                    )
                }
            }
        }

        stage('6. Terraform Apply') {
            when { expression { return params.RUN_TERRAFORM_APPLY } }
            steps {
                withCredentials([
                    file(credentialsId: 'gcp-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS'),
                    sshUserPrivateKey(credentialsId: 'gcp-vm-ssh-verified', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')
                ]) {
                    dir("terraform/${params.ENVIRONMENT}") {
                        sh '''
                            set -eu
                            echo "Validating Jenkins SSH private key..."

                            ssh-keygen -y -f "$SSH_KEY" > /tmp/jenkins_ssh_public_key

                            export TF_VAR_ssh_public_key="$(cat /tmp/jenkins_ssh_public_key)"

                            rm -f /tmp/jenkins_ssh_public_key

                            if [ -z "$TF_VAR_ssh_public_key" ]; then
                                echo "ERROR: SSH public key is empty"
                                exit 1
                            fi

                            echo "SSH private key validation successful."
                            terraform apply -input=false tfplan
                            terraform output -json > ../../ansible/inventory/terraform-output.json
                        '''
                    }
                }
            }
        }

        stage('7. Generate Ansible Inventory') {
            when { expression { return params.RUN_TERRAFORM_APPLY } }
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'gcp-vm-ssh-verified', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')
                ]) {
                    sh '''
                        set -eu
                        python3 scripts/generate_inventory.py \
                            --terraform-output ansible/inventory/terraform-output.json \
                            --inventory ansible/inventory/generated.ini \
                            --ssh-user "$SSH_USER"
                        ansible-inventory -i ansible/inventory/generated.ini --list
                    '''
                }
            }
        }

        stage('8. Configure Docker Hosts') {
            when { expression { return params.RUN_TERRAFORM_APPLY } }
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'gcp-vm-ssh-verified', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')
                ]) {
                    sh '''
                        set -eu
                        ansible-playbook \
                            -i ansible/inventory/generated.ini \
                            --private-key "$SSH_KEY" \
                            --user "$SSH_USER" \
                            ansible/playbooks/docker_setup.yml
                    '''
                }
            }
        }

        stage('9. Build and Deploy Application') {
            when { expression { return params.RUN_TERRAFORM_APPLY } }
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'gcp-vm-ssh-verified', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')
                ]) {
                    sh '''
                        set -eu
                        ansible-playbook \
                            -i ansible/inventory/generated.ini \
                            --private-key "$SSH_KEY" \
                            --user "$SSH_USER" \
                            ansible/playbooks/deploy_app.yml \
                            --extra-vars "app_image=${APP_IMAGE}"
                    '''
                }
            }
        }

        stage('10. Smoke Test') {
            when { expression { return params.RUN_TERRAFORM_APPLY } }
            steps {
                sh '''
                    set -eu
                    python3 scripts/smoke_test.py ansible/inventory/generated.ini
                '''
            }
        }
    }

    post {
        always {
            sh '''
                rm -f terraform/*/tfplan
                rm -f ansible/inventory/terraform-output.json
                rm -f ansible/inventory/generated.ini
            '''
            echo 'Pipeline execution finished.'
        }
        success { echo "${params.ENVIRONMENT} pipeline completed successfully." }
        failure { echo 'Pipeline failed. Review the failed stage logs before rerunning.' }
    }
}
