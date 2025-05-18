pipeline {
    agent any // Jenkins'in uygun bir agent üzerinde çalışmasını sağlar

    environment {
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials' // Gereksiz boşluklar kaldırıldı
        DOCKER_IMAGE_NAME        = "omerfeyzioglu/cicd-k8s-app" // KENDİ DOCKERHUB KULLANICI ADINIZI VE İMAJ ADINIZI YAZIN, gereksiz boşluklar kaldırıldı
        KUBECONFIG_PATH          = 'C:/Users/oomer/.kube/config' // Senin mevcut kubeconfig dosyanın yolu, gereksiz boşluklar kaldırıldı
        K8S_DEPLOYMENT_NAME    = 'cicd-k8s-app-deployment' // Gereksiz boşluklar kaldırıldı
        K8S_CONTAINER_NAME       = 'cicd-k8s-app-container'  // Kapanış tırnağı eklendi, gereksiz boşluk kaldırıldı
        K8S_DEPLOYMENT_FILE      = 'k8s/deployment.yaml'     // Bu satır önemli, gereksiz boşluklar kaldırıldı
        K8S_SERVICE_FILE         = 'k8s/service.yaml'        // Gereksiz boşluklar kaldırıldı
    }

    stages {
        stage('Stage 1: Clone Project') {
            steps {
                echo 'Cloning the project from GitHub...'
                // GitHub reponuzun URL'sini ve branch'ini belirtin
                git branch: 'main', url: "https://github.com/omerfeyzioglu/cicd-k8s.git" // KENDİ GITHUB REPO URL'NİZİ YAZIN
            }
        }

        stage('Stage 2: Build and Create Jar') {
            steps {
                echo 'Building the project and creating JAR file...'
                // Maven projesi için (pom.xml dosyasının olduğu dizinde çalıştırılmalı)
                // Jenkins agent'ında Maven kurulu olmalı veya Jenkins Global Tool Configuration'da tanımlanmalı
                // Windows'ta 'sh' yerine 'bat' kullanın:
                bat 'mvnw.cmd clean package -DskipTests' // Eğer projenizde Maven Wrapper (mvnw.cmd) varsa
                // VEYA eğer Maven PATH'e ekliyse:
                // bat 'mvn clean package -DskipTests'
            }
        }

        stage('Stage 3: Create Docker Image') {
            steps {
                script {
                    echo 'Creating Docker image...'
                    // Commit hash'ini veya build numarasını tag olarak kullanabilirsiniz
                    def imageTag = "build-${env.BUILD_NUMBER}" // Veya commit hash: bat(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.FINAL_IMAGE_NAME = "${DOCKER_IMAGE_NAME}:${imageTag}"
                    // Dockerfile'ın bulunduğu dizinde çalıştırılmalı
                    docker.build(env.FINAL_IMAGE_NAME, "./")
                    echo "Docker image created: ${env.FINAL_IMAGE_NAME}"
                }
            }
        }

        stage('Stage 4: Login to Docker Hub') {
            steps {
                echo 'Logging in to Docker Hub...'
                // Jenkins'te tanımladığınız Docker Hub kimlik bilgisi ID'sini kullanın
                withCredentials([usernamePassword(credentialsId: DOCKERHUB_CREDENTIALS_ID, passwordVariable: 'DOCKERHUB_PASSWORD', usernameVariable: 'DOCKERHUB_USERNAME')]) {
                    // Docker CLI'nin Jenkins agent'ında PATH'e ekli olduğundan emin olun
                    // Windows'ta 'sh' yerine 'bat' kullanın:
                    bat "echo %DOCKERHUB_PASSWORD% | docker login -u %DOCKERHUB_USERNAME% --password-stdin"
                }
                echo 'Successfully logged in to Docker Hub.'
            }
        }

        stage('Stage 5: Push Image to Hub') {
            steps {
                script {
                    echo "Pushing Docker image ${env.FINAL_IMAGE_NAME} to Docker Hub..."
                    docker.image(env.FINAL_IMAGE_NAME).push()
                    // 'latest' tag'ini de push'lamak isterseniz ve Docker Hub'da imaj adınızla eşleşiyorsa:
                    // docker.tag(env.FINAL_IMAGE_NAME, "${DOCKER_IMAGE_NAME}:latest")
                    // docker.image("${DOCKER_IMAGE_NAME}:latest").push()
                    echo "Docker image pushed: ${env.FINAL_IMAGE_NAME}"
                }
            }
        }

        stage('Stage 6: Apply K8s Deployment and Set Image') {
            steps {
                script {
                    echo "Applying Kubernetes deployment manifest: ${K8S_DEPLOYMENT_FILE}"
                    // Önce deployment.yaml dosyasını uygula (yoksa oluşturur, varsa günceller)
                    bat "kubectl apply -f ${K8S_DEPLOYMENT_FILE} --kubeconfig=\"${KUBECONFIG_PATH}\""

                    // Kısa bir bekleme, deployment'ın API'de tam olarak işlenmesi için zaman tanıyabilir (opsiyonel)
                    // sleep 3

                    echo "Setting image for Kubernetes deployment ${K8S_DEPLOYMENT_NAME} to: ${env.FINAL_IMAGE_NAME}"
                    // Sonra imajı set et
                    bat "kubectl set image deployment/${K8S_DEPLOYMENT_NAME} ${K8S_CONTAINER_NAME}=${env.FINAL_IMAGE_NAME} --kubeconfig=\"${KUBECONFIG_PATH}\" --record"
                    echo "Kubernetes deployment image updated."
                }
            }
        }

        stage('Stage 7: Apply K8s Service') {
            steps {
                echo 'Applying Kubernetes service configuration...'
                // Windows'ta 'sh' yerine 'bat' kullanın:
                bat "kubectl apply -f ${K8S_SERVICE_FILE} --kubeconfig=\"${KUBECONFIG_PATH}\""
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
