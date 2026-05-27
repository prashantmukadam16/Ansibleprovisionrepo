pipeline {

    agent any

    environment {
        PROJECT_ID = "your-gcp-project-id"
        GOOGLE_APPLICATION_CREDENTIALS = credentials('gcp-key')
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                url: 'https://github.com/yourrepo/DevOps-Project.git'
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform/dev') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('terraform/dev') {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform/dev') {
                    sh 'terraform plan'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform/dev') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Ansible Ping') {
            steps {
                dir('ansible') {
                    sh 'ansible all -i inventory/dev.ini -m ping'
                }
            }
        }

        stage('Install NGINX') {
            steps {
                dir('ansible') {
                    sh 'ansible-playbook -i inventory/dev.ini playbooks/install_nginx.yml'
                }
            }
        }

        stage('Deploy Application') {
            steps {
                dir('ansible') {
                    sh 'ansible-playbook -i inventory/dev.ini playbooks/deploy_app.yml'
                }
            }
        }
    }

    post {
        success {
            echo 'Deployment Successful'
        }

        failure {
            echo 'Deployment Failed'
        }
    }
}
