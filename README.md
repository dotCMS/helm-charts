# helm-charts

# **DotCMS: Local Development Setup**

This guide explains how to configure the chart for local development while ensuring the security of certificates and private keys. Each developer must generate their own local certificate and add it as a Kubernetes Secret. The chart references this Secret by name and does not store any sensitive data.

---

## **Preparing the Environment**

### 1. **Install Prerequisites**

Before starting, ensure you have the following tools installed:

- **Docker Desktop**: [Installation Guide](https://docs.docker.com/desktop/install/mac-install/)
  Enable Kubernetes cluster in Docker Desktop following the instructions in the link. [Docker Desktop Kubernetes](https://docs.docker.com/desktop/kubernetes/)

- **kubectl**: [Installation Guide](https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/#install-kubectl-on-macos)

  ```bash
  brew install kubectl
  kubectl config use-context docker-desktop
  ```

- **Helm**: [Installation Guide](https://helm.sh/docs/intro/install/)

  ```bash
  brew install helm
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo update
  ```

- **mkcert**: [Installation Guide](https://web.dev/articles/how-to-use-local-https)

  Install `mkcert` via Homebrew:
  ```bash
  brew install mkcert
  mkcert -install
  ```

### 2. **Generate a Local Certificate**

Using mkcert, generate a certificate for the local domain:

1. Run the following command:

  ```bash
  mkcert dotcms.local
  ```

2. This will generate two files: `dotcms.local.pem` and `dotcms.local-key.pem`.
  
  * dotcms.local.pem: The certificate.
  * dotcms.local-key.pem: The private key.

  *Note*: If you encounter an error like `Error: mkcert: command not found`, ensure you have installed mkcert and added it to your PATH.

3. Add the domain to your `/etc/hosts` file:
    
    Edit the `/etc/hosts` file and add `dotcms.local` with the IP address of your local machine, e.g.:
    
    ```
    127.0.0.1 dotcms.local
    ```

### 3. **Install the Nginx Ingress Controller on Kubernetes**

  ```bash
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
  ```

  You can watch the status by running 
  
  ```bash
  kubectl get service --namespace ingress-nginx ingress-nginx-controller --output wide --watch'  
  ```

### 3. **Create a Kubernetes Secret**

Add the certificate and private key as a Kubernetes Secret:

1. Create the `dotcms-dev` namespace:
  
  ```bash
  kubectl create namespace dotcms-dev
  ```

  Check that the namespace was created successfully:

  ```bash
  kubectl get namespaces
  ```

2. Run this command for creating the Secret `developer-certificate-secret` in the `dotcms-dev` namespace:

  ```bash
  kubectl create secret tls developer-certificate-secret --namespace=dotcms-dev \
    --cert=dotcms.local.pem --key=dotcms.local-key.pem
  ```

3. Confirm the Secret was created successfully:

  ```bash
  kubectl get secrets developer-certificate-secret -n dotcms-dev
  ```

### 4. **Reference the Secret in the Chart**

To configure the chart to use your Secret, modify the values.yaml file:

Add the name of your Secret under the certificates section

  ```yaml
  certificates:
    secretName: developer-certificate-secret
    domain: dotcms.local
  ```

### 5. **Customize your chart values**

You can customize your chart values by modifying the values.yaml file. For example, you can change the `image` tag or the number of replicas of `dotcms` service. e.g.:

  ```yaml
  dotcms:
    image: dotcms/dotcms:trunk
    imagePullPolicy: Always
    replicaCount: 2
    customEnvVars:
      DOT_ES_AUTH_BASIC_PASSWORD: "some-value"
      DOT_INITIAL_ADMIN_PASSWORD: "some-value"
  ```

### 6. **Install the DotCMS Helm chart**
helm install dotcms ./dotcms -f values.local.yaml --namespace dotcms-dev
