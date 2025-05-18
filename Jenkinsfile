pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'
        DOCKER_IMAGE_NAME = "omerfeyzioglu/cicd-k8s-app"
        KUBECONFIG_PATH = 'C:/Users/oomer/.kube/config'
        K8S_DEPLOYMENT_NAME = 'cicd-k8s-app-deployment'
        K8S_CONTAINER_NAME = 'cicd-k8s-app-container'
        K8S_SERVICE_FILE = 'k8s/service.yaml'
    }

    stages {
        stage('Stage 1: Clone Project') {
            steps {
                echo 'Cloning the project from GitHub...'
                git branch: 'main', url: "https://github.com/omerfeyzioglu/cicd-k8s.git"
            }
        }

        stage('Stage 2: Build and Create Jar') {
            steps {
                echo 'Building the project and creating JAR file...'
                bat 'mvn clean package -DskipTests'
            }
        }

        stage('Stage 3: Create Docker Image') {
            steps {
                script {
                    echo 'Creating Docker image...'
                    def imageTag = "build-${env.BUILD_NUMBER}"
                    env.FINAL_IMAGE_NAME = "${DOCKER_IMAGE_NAME}:${imageTag}"
                    docker.build(env.FINAL_IMAGE_NAME, "./")
                    echo "Docker image created: ${env.FINAL_IMAGE_NAME}"
                }
            }
        }

        stage('Stage 4: Login to Docker Hub') {
            steps {
                echo 'Logging in to Docker Hub...'
                withCredentials([usernamePassword(credentialsId: DOCKERHUB_CREDENTIALS_ID, passwordVariable: 'DOCKERHUB_PASSWORD', usernameVariable: 'DOCKERHUB_USERNAME')]) {
                    bat "echo $DOCKERHUB_PASSWORD | docker login -u $DOCKERHUB_USERNAME --password-stdin"
                }
                echo 'Successfully logged in to Docker Hub.'
            }
        }

        stage('Stage 5: Push Image to Hub') {
            steps {
                script {
                    echo "Pushing Docker image ${env.FINAL_IMAGE_NAME} to Docker Hub..."
                    docker.image(env.FINAL_IMAGE_NAME).push()
                    // 'latest' tag'ini de push
                    // docker.tag(env.FINAL_IMAGE_NAME, "${DOCKER_IMAGE_NAME}:latest")
                    // docker.image("${DOCKER_IMAGE_NAME}:latest").push()
                    echo "Docker image pushed: ${env.FINAL_IMAGE_NAME}"
                }
            }
        }

        stage('Stage 6: Update K8s Deployment Image and Apply') {
            steps {
                script {
                    echo "Updating Kubernetes deployment ${K8S_DEPLOYMENT_NAME} with image: ${env.FINAL_IMAGE_NAME}"
                    bat "kubectl set image deployment/${K8S_DEPLOYMENT_NAME} ${K8S_CONTAINER_NAME}=${env.FINAL_IMAGE_NAME} --kubeconfig=${KUBECONFIG_PATH} --record"
                    echo "Kubernetes deployment updated."
                }
            }
        }

        stage('Stage 7: Apply K8s Service') {
            steps {
                echo 'Applying Kubernetes service configuration...'
                bat "kubectl apply -f ${K8S_SERVICE_FILE} --kubeconfig=${KUBECONFIG_PATH}"
                echo 'Kubernetes service applied.'
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished.'
            // cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}