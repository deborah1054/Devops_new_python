pipeline {
    agent any

    tools {
        // Assumes 'terraform' is configured in Jenkins > Global Tool Configuration
        terraform 'terraform' 
    }

    environment {
        // The ID of the Azure Service Principal credential you will store in Jenkins
        AZURE_CREDENTIALS_ID = 'your-azure-service-principal'
    }

    stages {
        stage('1. Checkout Code') {
            steps {
                // Get all the files (app.py, Dockerfile, main.tf, etc.)
                git 'https://github.com/your-username/your-python-project.git'
            }
        }

        stage('2. Terraform Apply (Create Infra)') {
            steps {
                // This block securely injects your Azure credentials as environment variables
                // Terraform (and 'az' CLI) automatically detects and uses them
                withCredentials([azureServicePrincipal(credentialsId: env.AZURE_CREDENTIALS_ID,
                                                   subscriptionIdVariable: 'ARM_SUBSCRIPTION_ID',
                                                   clientIdVariable: 'ARM_CLIENT_ID',
                                                   clientSecretVariable: 'ARM_CLIENT_SECRET',
                                                   tenantIdVariable: 'ARM_TENANT_ID')]) {
                    
                    // Initialize Terraform
                    sh 'terraform init'

                    // Apply the configuration to create the ACR and App Service
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('3. Build and Push Docker Image') {
            steps {
                // Use the same credentials for the Azure CLI
                withCredentials([azureServicePrincipal(credentialsId: env.AZURE_CREDENTIALS_ID,
                                                   subscriptionIdVariable: 'ARM_SUBSCRIPTION_ID',
                                                   clientIdVariable: 'ARM_CLIENT_ID',
                                                   clientSecretVariable: 'ARM_CLIENT_SECRET',
                                                   tenantIdVariable: 'ARM_TENANT_ID')]) {
                    script {
                        // 1. Log in to the Azure CLI
                        sh 'az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID'

                        // 2. Get the ACR login server from Terraform's output
                        def acrLoginServer = sh(script: 'terraform output -raw acr_login_server', returnStdout: true).trim()

                        // 3. Log Docker into the ACR
                        sh "az acr login --name ${acrLoginServer}"

                        // 4. Define the full image name
                        // This MUST match the DOCKER_CUSTOM_IMAGE_NAME in main.tf
                        def imageName = "${acrLoginServer}/python-app:latest"

                        // 5. Build and Push the image
                        echo "Building and pushing ${imageName}..."
                        sh "docker build -t ${imageName} ."
                        sh "docker push ${imageName}"
                    }
                }
            }
        }

        stage('4. Restart Web App (To Pull Image)') {
             steps {
                // Use the credentials one last time
                withCredentials([azureServicePrincipal(credentialsId: env.AZURE_CREDENTIALS_ID,
                                                   subscriptionIdVariable: 'ARM_SUBSCRIPTION_ID',
                                                   clientIdVariable: 'ARM_CLIENT_ID',
                                                   clientSecretVariable: 'ARM_CLIENT_SECRET',
                                                   tenantIdVariable: 'ARM_TENANT_ID')]) {
                    script {
                        // 1. Get the app and resource group names from Terraform
                        def appName = sh(script: 'terraform output -raw web_app_name', returnStdout: true).trim()
                        def rgName  = sh(script: 'terraform output -raw resource_group_name', returnStdout: true).trim()

                        // 2. Log in to the Azure CLI (safer to do it again)
                        sh 'az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID'

                        // 3. Restart the app. This forces App Service to pull the new 'latest' image.
                        echo "Restarting Web App ${appName} to pull the new image..."
                        sh "az webapp restart --name ${appName} --resource-group ${rgName}"
                    }
                }
            }
        }
    }
}