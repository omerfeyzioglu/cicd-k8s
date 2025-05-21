# CI/CD Pipeline for Spring Boot App with Jenkins, Docker & Kubernetes (Minikube)

This project demonstrates a complete Continuous Integration and Continuous Deployment (CI/CD) pipeline for a simple Spring Boot web application. The pipeline is orchestrated by Jenkins, containerized using Docker, and deployed to a local Kubernetes cluster managed by Minikube.

This project is developed as part of the SWE304 Project Study 4 (2025).

## Project Overview

The core goal of this project is to automate the entire lifecycle of a web application from code commit to deployment. When changes are pushed to the GitHub repository (or a pull request is merged to the main branch), Jenkins automatically triggers a pipeline that performs the following actions:

1.  **Clones** the latest code from the GitHub repository.
2.  **Builds** the Spring Boot application using Maven, producing a JAR file.
3.  **Creates a Docker image** of the application using the provided `Dockerfile`.
4.  **Logs into Docker Hub** using stored credentials.
5.  **Pushes the Docker image** to Docker Hub, tagged with the build number.
6.  **Applies the Kubernetes deployment configuration** (`deployment.yaml`) to the Minikube cluster. This step ensures the deployment exists or is updated.
7.  **Sets the image for the Kubernetes deployment** to the newly built and pushed Docker image.
8.  **Applies the Kubernetes service configuration** (`service.yaml`) to expose the application.

The project also demonstrates scaling the application to multiple pods within the Kubernetes cluster.

## Technologies Used

* **Java 17**: For the Spring Boot application.
* **Spring Boot 3.x**: Framework for the web application (single REST endpoint).
* **Maven**: Build tool for the Java application.
* **Docker**: For containerizing the Spring Boot application.
* **Docker Hub**: As the Docker image registry.
* **Jenkins**: CI/CD automation server orchestrating the pipeline.
    * Jenkins Pipeline (Groovy script - `Jenkinsfile`)
    * Docker Pipeline plugin
* **Kubernetes (K8s)**: Container orchestration platform.
* **Minikube**: For running a local single-node Kubernetes cluster.
* **Git & GitHub**: Version control and SCM.

## Project Structure

```text
cicd-k8s/
├── .mvn/
│   └── wrapper/
│       ├── maven-wrapper.jar
│       └── maven-wrapper.properties
├── k8s/
│   ├── deployment.yaml        # K8s Deployment definition
│   └── service.yaml           # K8s Service definition
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/example/cicdk8sapp/ # Main application package
│   │   │       ├── HelloController.java     # Sample REST controller
│   │   │       └── CicdK8sApplication.java  # Spring Boot main class
│   │   └── resources/
│   │       └── application.properties   # Spring Boot configuration (e.g., server.port)
│   └── test/
│       └── java/
│           └── com/example/cicdk8sapp/
│               └── CicdK8sApplicationTests.java
├── .gitattributes
├── .gitignore
├── Dockerfile                 # Instructions to build the Docker image
├── Jenkinsfile                # Jenkins Pipeline script
├── mvnw                       # Maven wrapper script (Linux/macOS)
├── mvnw.cmd                   # Maven wrapper script (Windows)
└── pom.xml                    # Maven Project Object Model

```

## Prerequisites

Before running this project locally or setting up the pipeline, ensure you have the following installed and configured:

* Minikube (started with a driver like Docker)
* Jenkins (running, accessible, and necessary plugins installed: Docker Pipeline, Git, Pipeline, etc.)
* Docker (running and accessible by Jenkins)
* Git
* Maven (accessible by Jenkins, or use Maven Wrapper)
* `kubectl` CLI (configured to interact with your Minikube cluster)
* JDK 17

## Setup and Configuration

1.  **Clone the Repository:**
    ```bash
    git clone [https://github.com/omerfeyzioglu/cicd-k8s.git](https://github.com/omerfeyzioglu/cicd-k8s.git)
    cd cicd-k8s
    ```

2.  **Configure Jenkins:**
    * Create a new "Pipeline" project in Jenkins.
    * Under "Pipeline" configuration, select "Pipeline script from SCM".
    * Choose "Git" as SCM.
    * Set **Repository URL** to your forked GitHub repository URL (e.g., `https://github.com/omerfeyzioglu/cicd-k8s.git`).
    * Ensure **Branch Specifier** is `*/main` (or your primary branch).
    * Set **Script Path** to `Jenkinsfile`.
    * **Credentials:**
        * Add your Docker Hub credentials to Jenkins with an ID like `dockerhub-credentials`.
        * If your GitHub repository is private, add appropriate GitHub credentials.
    * **Environment Variables in `Jenkinsfile`**:
        * Update `DOCKER_IMAGE_NAME` with your Docker Hub username and desired image name (e.g., `yourdockerhubusername/cicd-k8s-app`).
        * Verify `KUBECONFIG_PATH` points to the correct location of your `kubeconfig` file that Jenkins can access (e.g., `C:/Users/yourusername/.kube/config` for Windows if Jenkins runs as your user, or a Jenkins-specific path if you've set one up).
        * Update the `git url` in `Stage 1` of the `Jenkinsfile` if you are using a fork.

3.  **Update `k8s/deployment.yaml`:**
    * Ensure the `image` field in `deployment.yaml` (e.g., `omerfeyzioglu/cicd-k8s-app:latest`) matches the base image name you intend to use or will be updated by the `kubectl set image` command in the Jenkins pipeline.

## Running the Pipeline

1.  Make a change to the application code or `Jenkinsfile`.
2.  Commit and push the changes to the `main` branch of your GitHub repository.
    ```bash
    git add .
    git commit -m "Your commit message"
    git push origin main
    ```
3.  If GitHub webhooks are configured, Jenkins should automatically trigger the pipeline. Otherwise, you can manually trigger a build from the Jenkins dashboard.
4.  Monitor the pipeline stages in Jenkins ("Console Output" or "Blue Ocean" view).

## Verifying the Deployment on Kubernetes (Minikube)

Once the Jenkins pipeline completes successfully:

1.  **Check Deployments:**
    ```bash
    kubectl get deployments
    ```
    You should see `cicd-k8s-app-deployment` with `READY` status `1/1`.

2.  **Check Pods:**
    ```bash
    kubectl get pods
    ```
    You should see a pod related to `cicd-k8s-app-deployment` in `Running` status and `READY 1/1`. If not, use:
    ```bash
    kubectl describe pod <your-pod-name>
    kubectl logs <your-pod-name>
    ```
    to troubleshoot.

3.  **Check Services:**
    ```bash
    kubectl get services
    ```
    You should see `cicd-k8s-app-service`.

4.  **Access the Application:**
    If using `NodePort` for the service type:
    ```bash
    minikube service cicd-k8s-app-service --url
    ```
    Open the provided URL in your browser. You should see the Spring Boot application's greeting message.

## Scaling the Application

To scale the application to 2 pods (as per project requirements):

1.  Run the following command:
    ```bash
    kubectl scale deployment cicd-k8s-app-deployment --replicas=2
    ```
2.  Verify that two pods are running:
    ```bash
    kubectl get pods
    ```
3.  Access the application again via the service URL. Kubernetes will load balance requests between the two pods.

## Troubleshooting

Refer to the "Sorun Giderme (Troubleshooting)" section in the `project4_adaptation_plan.md` document (or the shared Canvas document) for common issues and solutions related to:
* Jenkins pipeline failures
* `kubectl` version compatibility
* `KUBECONFIG_PATH` and access permissions
* Minikube network issues
* Kubernetes deployment events (e.g., `ImagePullBackOff`, `CrashLoopBackOff`)
* Jenkins Git integration issues
* Shell command errors on Windows
* Docker base image not found errors
* `Jenkinsfile` syntax errors

---


