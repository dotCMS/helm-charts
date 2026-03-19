# Spec 01: Customer Manifest Discovery

## Context

Before evaluating ANY templating tool, we must understand what we actually have. Each customer in `infrastructure-as-code/kubernetes/customers/` has hand-crafted YAML that encodes implicit business logic, operational decisions, and per-customer customizations. This spec extracts that knowledge into a structured, machine-readable format.

This is the foundational data collection phase. Every subsequent phase depends on its output.

## Skill

Load `platform-devops-architect` before execution. The agent needs deep understanding of Kubernetes resource semantics to distinguish functional fields from cosmetic differences.

## Inputs

For a given customer `{CUSTOMER}`:

```
infrastructure-as-code/kubernetes/customers/{CUSTOMER}/
├── namespace/
│   ├── network-policies/          # deny-all.yaml, dotcms.yaml, inter-ns.yaml, linkerd.yaml
│   ├── service-account/           # service-account.yaml
│   ├── volumes/                   # pv.yaml, pvc.yaml
│   └── secrets/                   # awssecretprovider.yaml, sealed.yaml (optional)
├── {env-1}/                       # e.g., prod, prod-1, test, staging
│   ├── statefulset.yaml
│   ├── alb.yaml                   # Contains both Service and Ingress
│   └── services.yaml
├── {env-2}/
│   └── ...
└── ...
```

Not all customers follow this exact structure. The agent MUST handle variations gracefully and document them.

## Task

For the target customer, perform the following analysis:

### Step 1: Enumerate Structure

List all environments and files present. Note any deviations from the standard structure (extra files, missing files, non-standard directory names).

### Step 2: Extract StatefulSet Fields (per environment)

For each environment's `statefulset.yaml`, extract:

**Identity:**
- namespace, name, labels, serviceName
- serviceAccountName

**Workload Config:**
- replicas
- podManagementPolicy
- terminationGracePeriodSeconds
- image (repository + tag separately)
- resources (requests and limits for cpu and memory)

**Environment Variables:**
Classify each env var into one of these categories:
- `secret_ref`: Uses valueFrom.secretKeyRef (extract secret name and key)
- `static_value`: Hardcoded value (extract the value)
- `computed`: Derived from other values (document the derivation)

Group env vars by function:
- database (DB_BASE_URL, DB_DNSNAME, DB_USERNAME, DB_PASSWORD)
- elasticsearch/opensearch (DOT_ES_*)
- mail/smtp (DOT_MAIL_*)
- cache (CACHE_*, DOT_CACHE_*)
- java (CMS_JAVA_OPTS, including parsed -Xmx value)
- security (DOT_COOKIES_*, DOT_REMOTE_CALL_*, COOKIES_SECURE_FLAG)
- reindex (DOT_REINDEX_*)
- features (DOT_FEATURE_FLAG_*, TOMCAT_REDIS_*, GLOWROOT_*)
- telemetry (DOT_TELEMETRY_*)
- other (anything not in above categories)

**Probes:**
- startupProbe (path, port, initialDelay, period, failure threshold, timeout)
- livenessProbe (same fields)
- readinessProbe (same fields)

**Affinity:**
- Type: required vs preferred
- TopologyKey
- Label selector

**Volumes:**
- PVC claim name
- CSI secret store (if present)
- Any additional volume mounts

**Lifecycle Hooks:**
- postStart command (if any)
- preStop command (sleep duration)

**Annotations:**
- Linkerd injection (enabled/disabled, proxy settings)
- Prometheus scraping (if present)
- Any other annotations

### Step 3: Extract Ingress/ALB Fields (per environment)

For each environment's `alb.yaml`:
- Ingress class (alb vs nginx)
- Scheme (internet-facing vs internal)
- Target type
- SSL certificate ARN(s)
- SSL policy
- Security groups
- Health check configuration (protocol, port, path, intervals, thresholds)
- Target group attributes (stickiness, slow start, deregistration delay)
- Load balancer attributes (idle timeout, access logs, WAF)
- Host rules (default host, additional hosts)
- Tags (Vanta compliance, client name)

### Step 4: Extract Service Fields (per environment)

For each environment's `services.yaml`:
- Service type (NodePort, ClusterIP, etc.)
- Port mapping
- Selector labels

### Step 5: Extract Namespace-Level Resources

From the `namespace/` directory:
- Network policies (what's present, any custom rules beyond standard set)
- Service account name and annotations (IAM role ARN if present)
- PV/PVC details (storage class, access point, volume handle, capacity)
- Secret provider class (AWS secrets ARN, synced secret names)
- Sealed secrets (if present, note existence without extracting values)

### Step 6: Cross-Environment Comparison

Within this single customer, compare all environments:
- What fields are identical across all envs? (these are customer-level, not env-level)
- What fields vary per env? (these are the env-specific overrides)
- Any environments that deviate significantly from the pattern?

## Output Schema

Produce a JSON file at `outputs/discovery/{CUSTOMER}.json`:

```json
{
  "customer": "string — customer directory name",
  "discoveryDate": "ISO 8601 timestamp",
  "structure": {
    "environments": ["list of environment directory names"],
    "hasNamespaceDir": true,
    "deviations": ["list of structural deviations from standard pattern"]
  },
  "customerLevel": {
    "namespace": "string",
    "serviceAccountName": "string",
    "iamRoleArn": "string or null",
    "awsSecretsArn": "string or null",
    "cloudProvider": "aws | gcp | local",
    "region": "string",
    "networkPolicies": {
      "standard": ["list of standard policies present"],
      "custom": ["list of non-standard policies"]
    },
    "volumes": {
      "storageClass": "string",
      "accessPoint": "string",
      "volumeHandle": "string"
    }
  },
  "environments": {
    "{envName}": {
      "identity": {
        "fullName": "string — StatefulSet name",
        "labels": {}
      },
      "workload": {
        "replicas": "number",
        "podManagementPolicy": "string",
        "terminationGracePeriodSeconds": "number",
        "image": {
          "repository": "string",
          "tag": "string",
          "fullImage": "string"
        },
        "resources": {
          "requests": { "cpu": "string", "memory": "string" },
          "limits": { "cpu": "string", "memory": "string" }
        },
        "javaHeap": "string — parsed from CMS_JAVA_OPTS -Xmx value"
      },
      "envVars": {
        "database": { "varName": { "type": "secret_ref|static_value", "value": "..." } },
        "elasticsearch": {},
        "mail": {},
        "cache": {},
        "java": {},
        "security": {},
        "reindex": {},
        "features": {},
        "telemetry": {},
        "other": {}
      },
      "probes": {
        "startup": {},
        "liveness": {},
        "readiness": {}
      },
      "affinity": {
        "type": "required | preferred | none",
        "topologyKey": "string",
        "labelSelector": {}
      },
      "lifecycle": {
        "postStart": "string or null",
        "preStopSleepSeconds": "number"
      },
      "annotations": {
        "linkerd": { "enabled": "boolean", "proxyWaitBeforeExit": "number or null" },
        "prometheus": { "enabled": "boolean", "port": "string or null", "path": "string or null" },
        "other": {}
      },
      "ingress": {
        "class": "alb | nginx",
        "certificateArns": ["list"],
        "sslPolicy": "string",
        "securityGroups": ["list"],
        "healthcheck": {},
        "targetGroupAttributes": {},
        "loadBalancerAttributes": {},
        "hosts": { "default": "string", "additional": ["list"] },
        "tags": {}
      },
      "service": {
        "type": "string",
        "ports": []
      }
    }
  },
  "crossEnvAnalysis": {
    "sharedFields": ["list of fields identical across all environments"],
    "envSpecificFields": {
      "{fieldPath}": {
        "values": { "{envName}": "value" },
        "note": "why this varies"
      }
    }
  },
  "anomalies": [
    {
      "field": "field path",
      "description": "what's unusual",
      "severity": "info | warning | critical",
      "recommendation": "what to do about it"
    }
  ]
}
```

## Validation Criteria

1. **Completeness:** Every YAML file in the customer directory has been read and its fields extracted.
2. **Accuracy:** Spot-check 3 random fields against the source YAML — they must match exactly.
3. **Classification:** Every env var is classified into exactly one category.
4. **Cross-env analysis:** The shared vs env-specific split is correct (a field marked "shared" truly has the same value in all environments).
5. **Anomalies:** Any field that deviates from what other customers typically have is flagged.

## Exit Criteria

- JSON output file exists at `outputs/discovery/{CUSTOMER}.json`
- JSON is valid (parseable)
- All environments listed in `structure.environments` have corresponding entries in `environments`
- No unclassified env vars (everything in a category)
- Cross-env analysis is populated
