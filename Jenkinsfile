pipeline {

    agent any

    environment {
        PROJECT_ID = "batch43-496010"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                url: 'https://github.com/prashantmukadam16/Ansibleprovisionrepo.git'
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([file(credentialsId: 'gcp-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {

                    sh '''
                    echo "Credential File:"
                    echo $GOOGLE_APPLICATION_CREDENTIALS

                    ls -l $GOOGLE_APPLICATION_CREDENTIALS
                    '''

                    dir('terraform/dev') {
                        sh 'terraform init -reconfigure'
                    }
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
                withCredentials([file(credentialsId: 'gcp-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {

                    dir('terraform/dev') {
                        sh 'terraform plan'
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([file(credentialsId: 'gcp-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {

                    dir('terraform/dev') {
                        sh 'terraform apply -auto-approve'
                    }
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