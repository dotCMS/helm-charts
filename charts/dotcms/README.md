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


1. Run this command for creating the Secret `developer-certificate-secret` in the `dotcms-dev` namespace:

  ```bash
  kubectl create secret tls developer-certificate-secret --namespace=dotcms-dev --create-namespace \
    --cert=dotcms.local.pem --key=dotcms.local-key.pem
  ```

2. Confirm the Secret was created successfully:

  ```bash
  kubectl get secrets developer-certificate-secret -n dotcms-dev
  ```

### 4. **Clone the DotCMS Helm chart**

Clone the DotCMS Helm chart repository:

  ```bash
  git clone git@github.com:dotCMS/helm-charts.git
  ```

### 5. **Install the DotCMS Helm chart**

Go to the `helm-charts` directory and install the chart:

  ```bash
  cd helm-charts/charts
  ```

  ```bash
  helm install dotcms ./dotcms --namespace dotcms-dev --create-namespace
  ```

### 6. **Helper tools**

  You can use the following resources to help you with the setup:

  - [DotCMS Utilities](https://github.com/dotCMS/dotcms-utilities/tree/main/dev-k8s-local-setup#dotcms-local-development-setup-using-kubernetes)

  This tool automates the setup of a local development environment for DotCMS using Kubernetes. It ensures that all necessary tools and configurations are in place before installing the DotCMS Helm chart.

## 7. **Values**

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity.requireDifferentHosts | bool | `false` | Enforce pods to be scheduled on different nodes |
| app | string | `dotcms` | Application name |
| backup.excludes | list | `["assets/tmp_upload*", "assets/dotGenerated/", "assets/timemachine/", "assets/bundles/*", "assets/server/sql_backups/"]` | List of paths to exclude from backups |
| backup.fileName | string | `backup-complete` | Name of the file created after successful backup |
| backup.operation | string | `none` | Backup operation type (e.g., none, scheduled, manual) |
| backup.path | string | `/data/shared/backups` | Directory path inside the container where backups are stored |
| cloudProvider | string | `local` | Cloud provider (e.g., aws, gcp, local) |
| configVersion | int | `1` | Configuration version for tracking changes |
| coreServiceEnabled | bool | `true` | Enable or disable the core service |
| customerName | string | `dotcms-dev` | Customer identifier |
| database.host | string | `db` | Hostname for the database server |
| database.local.enabled | bool | `true` | Enable the local database container |
| database.local.image | string | `pgvector/pgvector:pg16` | Docker image to use for the local database |
| database.local.resources.limits.cpu | string | `500m` | Maximum CPU allowed for the database |
| database.local.resources.limits.memory | string | `3Gi` | Maximum memory allowed for the database |
| database.local.resources.requests.cpu | string | `100m` | Minimum CPU requested by the database |
| database.local.resources.requests.memory | string | `3Gi` | Minimum memory requested by the database |
| database.name | string | `dotcms` | Name of the PostgreSQL database |
| database.port | int | `5432` | Port number for the database server |
| database.secretNameOverride | string | `""` | Override the secret name used for database credentials (leave empty to use default) |
| envVarsDefaults.CMS_JAVA_OPTS | string | `-XX:+PrintFlagsFinal -Djdk.lang.Process.launchMechanism=fork` | Custom JVM options for DotCMS |
| envVarsDefaults.CUSTOM_STARTER_URL | string | `{{ include "dotcms.customStarter.url" . }}` | Starter content URL for initializing DotCMS |
| envVarsDefaults.DB_BASE_URL | string | `{{ printf "jdbc:postgresql://%s:%v/%s" (.Values.database.host \| default "db") (int .Values.database.port) (include "dotcms.db.name" .) }}` | Full JDBC URL to connect to the database |
| envVarsDefaults.DB_DNSNAME | string | `{{ .Values.database.host \| default "db" }}` | Database hostname used in JDBC connections |
| envVarsDefaults.DB_PASSWORD | string | `{{ printf "SECRET:%s:password" (include "dotcms.secret.env.name" (dict "Values" .Values "secretName" "database" "overridePath" "database.secretNameOverride")) }}` | Secret value using the format SECRET:<secretName>:<key> |
| envVarsDefaults.DB_USERNAME | string | `{{ printf "SECRET:%s:username" (include "dotcms.secret.env.name" (dict "Values" .Values "secretName" "database" "overridePath" "database.secretNameOverride")) }}"` | Secret value using the format SECRET:<secretName>:<key> |
| envVarsDefaults.DOT_COOKIES_HTTP_ONLY | string | `false` | If true, cookies are set with HttpOnly flag |
| envVarsDefaults.DOT_DOTCMS_CLUSTER_ID | string | `{{ include "dotcms.opensearch.cluster" . }}` | OpenSearch cluster ID |
| envVarsDefaults.DOT_DOTGENERATED_DEFAULT_PATH | string | `shared` | Default path for dot-generated content |
| envVarsDefaults.DOT_ES_AUTH_BASIC_PASSWORD | string | `{{ printf "SECRET:%s:password" (include "dotcms.secret.shared.name" (dict "Values" .Values "secretName" "elasticsearch" "overridePath" "opensearch.secretNameOverride")) }}"` | Secret value using the format SECRET:<secretName>:<key>   |
| envVarsDefaults.DOT_ES_AUTH_BASIC_USER | string | `{{ printf "SECRET:%s:username" (include "dotcms.secret.shared.name" (dict "Values" .Values "secretName" "elasticsearch" "overridePath" "opensearch.secretNameOverride")) }}"` | Secret value using the format SECRET:<secretName>:<key>   |
| envVarsDefaults.DOT_ES_AUTH_TYPE | string | `BASIC` | Authentication type for OpenSearch (e.g., BASIC) |
| envVarsDefaults.DOT_ES_ENDPOINTS | string | `{{ include "dotcms.opensearch.endpoints" . }}"` | List of OpenSearch endpoints |
| envVarsDefaults.DOT_FEATURE_FLAG_TELEMETRY | string | `{{ .Values.telemetry.enabled }}` | Toggle telemetry features via feature flag |
| envVarsDefaults.DOT_INITIAL_ADMIN_PASSWORD | string | `{{ printf "SECRET:%s:password" (include "dotcms.secret.env.name" (dict "Values" .Values "secretName" "dotcms-admin")) }}"` | Secret value using the format SECRET:<secretName>:<key>  |
| envVarsDefaults.DOT_MAIL_SMTP_PASSWORD | string | `{{ printf "SECRET:%s:password" (include "dotcms.secret.shared.name" (dict "Values" .Values "secretName" "ses")) }}` | Secret value using the format SECRET:<secretName>:<key>   |
| envVarsDefaults.DOT_MAIL_SMTP_USER | string | `{{ printf "SECRET:%s:username" (include "dotcms.secret.shared.name" (dict "Values" .Values "secretName" "ses")) }}"` | Secret value using the format SECRET:<secretName>:<key>   |
| envVarsDefaults.DOT_REINDEX_THREAD_MINIMUM_RUNTIME_IN_SEC | string | `120` | Minimum runtime (in seconds) for reindex threads |
| envVarsDefaults.DOT_REMOTE_CALL_ALLOW_REDIRECTS | string | `true` | Whether remote calls should follow redirects |
| envVarsDefaults.DOT_REMOTE_CALL_SUBNET_BLACKLIST | string | `"169.254.169.254/32127.0.0.1/3210.0.0.0/8172.16.0.0/12192.168.0.0/16"` | List of IPs/subnets to block from making remote calls |
| envVarsDefaults.DOT_SYSTEM_STATUS_API_IP_ACL | string | `0.0.0.0/0` | CIDR block allowed to query the system status API |
| envVarsDefaults.DOT_TELEMETRY_CLIENT | string | `{{ .Values.telemetry.telemetryClient }}` | Client identifier for telemetry |
| envVarsDefaults.DOT_TELEMETRY_SAVE_SCHEDULE | string | `0 0 */8 * * ?` | Cron schedule for telemetry data submission |
| envVarsDefaults.DOT_URI_NORMALIZATION_FORBIDDEN_REGEX | string | `\\/\\/html\\/.*` | Regex to block unwanted URIs from being processed |
| environmentType | string | `local-dev` | Deployment environment type (e.g., local-dev, qa, prod, staff-sandbox, customer-sandbox) |
| environments.prod | object | `{"envVarsOverrides":{}}` | You can define multiple environments (e.g., prod, staging, auth). 'prod' is the default environment included in the chart |
| environments.prod.envVarsOverrides | object | `{}` | Environment variable overrides for the 'prod' environment |
| hostType | string | `corp` | Type of host (e.g., corp, sh) |
| imagePullPolicy | string | `IfNotPresent` | Image pull policy (Always, IfNotPresent, Never) |
| ingress.alb.hosts.accessLogs.bucketOverride | string | `""` | Override for the S3 bucket for access logs |
| ingress.alb.hosts.accessLogs.enabled | bool | `false` | Enable ALB access logs |
| ingress.alb.hosts.accessLogs.prefixOverride | string | `""` | Prefix override for access logs in S3 |
| ingress.alb.hosts.additionalCertificateArns | list | `[]` | Additional certificate ARNs for ALB |
| ingress.alb.hosts.additionalHosts | list | `[]` | Additional ALB hosts |
| ingress.alb.hosts.default | object | `true` | Enable default ALB host |
| ingress.alb.hosts.default.certificateArn | string | `""` | ARN of the TLS certificate for the ALB host |
| ingress.alb.hosts.default.hostSuffix | string | `.dotcms.cloud` | Host suffix for default ALB host |
| ingress.alb.hosts.default.sslPolicy | string | `""` | SSL policy name for the ALB |
| ingress.alb.hosts.idleTimeout | int | `3600` | ALB idle timeout in seconds |
| ingress.alb.hosts.stickySessions | object | `{"duration":18000,"enabled":false}` | Sticky session configuration for ALB |
| ingress.alb.hosts.stickySessions.duration | int | `18000` | Sticky session duration in seconds |
| ingress.alb.hosts.stickySessions.enabled | bool | `false` | Enable sticky sessions |
| ingress.alb.hosts.wafArn | string | `""` | ARN of the WAF to associate with the ALB |
| ingress.alb.securityGroups.additional | list | `[]` | Additional security groups to attach |
| ingress.alb.securityGroups.default | list | `[]` | List of default security groups |
| ingress.alb.securityGroups.useDefaults | bool | `true` | Use default security groups |
| ingress.host | string | `""` | Optional custom ingress host |
| ingress.hostSuffix | string | `dotcms.local` | Default suffix for ingress hostnames |
| ingress.tlsSecretName | string | `developer-certificate-secret` | TLS secret name used for HTTPS ingress |
| ingress.type | string | `nginx` | Ingress controller type ("nginx" or "alb") |
| javaMemory | int | `2` | Maximum heap size for the JVM (in Gi) |
| linkerd.enabled | bool | `false` | Enable Linkerd sidecar injection |
| livenessProbe.failureThreshold | int | `1` | Number of failures before restarting the container |
| livenessProbe.httpGet.path | string | `/api/v1/appconfiguration` | Path to check liveness |
| livenessProbe.httpGet.port | int | `8082` | Port used for the liveness probe |
| livenessProbe.initialDelaySeconds | int | `1` | Initial delay before the first liveness check |
| livenessProbe.periodSeconds | int | `30` | Frequency of liveness checks |
| livenessProbe.successThreshold | int | `1` | Number of successes needed for the container to be considered alive |
| livenessProbe.timeoutSeconds | int | `10` | Timeout for the probe request |
| mail.enabled | bool | `false` | Enable SMTP mail configuration |
| mail.smtp.auth | string | `true` | Whether SMTP authentication is required |
| mail.smtp.host | string | `""` | SMTP server hostname |
| mail.smtp.port | int | `587` | SMTP server port |
| mail.smtp.secretNameOverride | string | `""` | Override the name of the secret for SMTP credentials |
| mail.smtp.sslProtocols | string | `TLSv1.2` | SSL/TLS protocols to use for secure connection |
| opensearch.authType | string | `BASIC` | Authentication type for OpenSearch (e.g., BASIC) |
| opensearch.clusterIdOverride | string | `""` | Override for the OpenSearch cluster identifier |
| opensearch.endpointUrl | string | `"{{ .Values.opensearch.protocol }}://{{ .Values.opensearch.host }}:{{ .Values.opensearch.port }}"` | Computed endpoint URL for OpenSearch access |
| opensearch.host | string | `nil` | Hostname of the OpenSearch service (leave empty if using local) |
| opensearch.javaOpts | string | `-Xmx1G` | Java options passed to the OpenSearch JVM |
| opensearch.local.enabled | bool | `true` | Enable the local OpenSearch container |
| opensearch.local.image | string | `opensearchproject/opensearch:1` | Docker image to use for the local OpenSearch instance |
| opensearch.port | int | `9200` | Port on which OpenSearch listens |
| opensearch.protocol | string | `http` | Protocol to use for OpenSearch communication (http or https) |
| opensearch.secretNameOverride | string | `""` | Override the name of the secret containing OpenSearch credentials |
| readinessProbe.failureThreshold | int | `1` | Number of failures before marking the pod as not ready |
| readinessProbe.httpGet.path | string | `/api/v1/appconfiguration` | Path to check readiness |
| readinessProbe.httpGet.port | int | `8082` | Port used for the readiness probe |
| readinessProbe.initialDelaySeconds | int | `1` | Initial delay before the first readiness check |
| readinessProbe.periodSeconds | int | `10` | Frequency of readiness checks |
| readinessProbe.successThreshold | int | `1` | Number of successes required to be considered ready |
| readinessProbe.timeoutSeconds | int | `5` | Timeout for the readiness probe |
| redis.host | string | `""` | Hostname of the external Redis instance (if not using local) |
| redis.local.enabled | bool | `true` | Enable the local Redis container |
| redis.local.image | string | `redis:latest` | Docker image used for local Redis |
| redis.password | string | `""` | Redis password (leave empty to use secret) |
| redis.port | int | `6379` | Port number for Redis service |
| redis.secretNameOverride | string | `""` | Override the secret name for Redis credentials |
| redis.sessionHost | string | `redis` | Hostname used for Redis-backed sessions |
| redis.sessionPersistentPolicies | string | `DEFAULT` | Redis session persistence policy |
| redis.sslEnabled | bool | `true` | Enable SSL/TLS for Redis communication |
| replicas | int | `1` | Number of replicas to deploy |
| repository | string | `dotcms/dotcms-test` | Docker image repository |
| resources.limits.cpu | int | `2` | Maximum CPU allowed |
| resources.limits.memory | string | `5Gi` | Maximum memory allowed |
| resources.requests.cpu | string | `500m` | Minimum CPU requested |
| resources.requests.memory | string | `5Gi` | Minimum memory requested |
| scaleDownBeforeUpgrade | bool | `false` | Scale down before upgrading |
| secrets.createSecrets | bool | `true` | Whether to create secrets automatically |
| secrets.sync.env.database.keys | list | `[username, password]` | Required keys for the secret |
| secrets.sync.env.database.type | string | `kubernetes.io/basic-auth` | Type of Kubernetes secret |
| secrets.sync.env.dotcms-admin.keys | list | `[password]` | Required key for the secret |
| secrets.sync.env.dotcms-admin.type | string | `kubernetes.io/basic-auth` | Type of Kubernetes secret |
| secrets.sync.shared.elasticsearch.keys | list | `[username, password]` | Required keys for the secret |
| secrets.sync.shared.elasticsearch.type | string | `kubernetes.io/basic-auth` | Type of Kubernetes secret |
| secrets.sync.shared.license.keys | list | `[license]` | Required key for the license file |
| secrets.sync.shared.license.type | string | `Opaque` | Type of Kubernetes secret |
| secrets.sync.shared.ses.keys | list | `[username, password]` | Required keys for the secret |
| secrets.sync.shared.ses.type | string | `kubernetes.io/basic-auth` | Type of Kubernetes secret |
| secrets.useSecretsStoreCSI | bool | `false` | Use CSI driver to mount secrets from external store |
| serviceAccount.create | bool | `false` | Whether to create a dedicated Kubernetes service account |
| startupProbe.failureThreshold | int | `60` | Number of failed checks before container is restarted |
| startupProbe.httpGet.path | string | `/api/v1/appconfiguration` | Path to check for readiness |
| startupProbe.httpGet.port | int | `8082` | Port used for the readiness probe |
| startupProbe.initialDelaySeconds | int | `60` | Initial delay before the first probe is initiated |
| startupProbe.periodSeconds | int | `5` | Frequency of probe checks in seconds |
| startupProbe.successThreshold | int | `1` | Number of successful checks required before marking as healthy |
| startupProbe.timeoutSeconds | int | `20` | Time in seconds after which the probe times out |
| tag | string | `1.0.0-SNAPSHOT` | Docker image tag |
| telemetry.enabled | bool | `false` | Enable or disable telemetry |
| telemetry.telemetryClient | string | `DEV` | Client name used for telemetry reporting (e.g., DEV, PROD) |
| terminationGracePeriodSeconds | int | `10` | Termination grace period in seconds |

