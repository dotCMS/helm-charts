# Spec 02: Convention Extraction — Cross-Customer Pattern Analysis

## Context

Phase 1 produced a structured discovery JSON for each customer. This phase analyzes ALL discovery outputs together to answer: "What are the REAL conventions across our 84 customers?" This separates signal from noise, defaults from overrides, patterns from drift.

This is the most strategically valuable phase. Its output defines what the "gold master" template must produce by default and what must be parameterized.

## Skill

Load `engineering:tech-debt` before execution. This is fundamentally a technical debt categorization exercise: identifying patterns, drift, and one-offs across a large codebase.

Also load `platform-devops-architect` for Kubernetes domain expertise.

## Inputs

All discovery outputs from Phase 1:

```
outputs/discovery/*.json     # One per customer (84 files expected)
```

## Task

### Step 1: Field Frequency Analysis

For every field extracted in Phase 1, compute:
- How many customers have this field?
- What are the distinct values?
- What is the most common value (mode)?
- What is the distribution?

Group results into:

- **Universal (100%):** Every customer has this field with the same value → This is a HARD DEFAULT in the template
- **Universal variable (100%):** Every customer has this field but values differ → This is a REQUIRED PARAMETER
- **Common (>70%):** Most customers have this, some don't → This is an OPTIONAL FEATURE with a default
- **Minority (<30%):** Few customers have this → This is a CUSTOMER-SPECIFIC OVERRIDE
- **Unique (1 customer):** Only one customer has this → This is an ANOMALY to investigate

### Step 2: Default Value Extraction

For each field, determine the production-safe default:
- If >80% of customers use the same value → That value is the default
- If values cluster around 2-3 options → Document the clusters and pick the safest
- If values are widely distributed → No default; this is a required parameter

Pay special attention to:
- `terminationGracePeriodSeconds` — what do most customers use?
- `preStop` sleep duration — what's the most common?
- `affinity` type — how many use required vs preferred vs none?
- `replicas` — what's the distribution?
- `DOT_COOKIES_HTTP_ONLY` — what's the majority setting?
- Probe configurations — how much do they actually vary?

### Step 3: Naming Convention Analysis

Analyze the naming patterns across all customers:
- StatefulSet name pattern: `dotcms-{customer}-{env}` — is this universal?
- Service name pattern: `{customer}-{env}-svc` — universal?
- PVC name pattern: `{customer}-{env}-efs-pvc` — universal?
- Secret name pattern: `sh-{customer}-awssecret-{type}` — universal?
- Ingress host pattern: `{customer}-{env}-{version}.dotcms.cloud` — or are there variations?

Document any customers that deviate from these patterns.

### Step 4: Feature Flag Mapping

Identify all optional features and their adoption:
- Linkerd injection: which customers have it enabled?
- Prometheus scraping: which customers?
- Glowroot monitoring: which customers?
- Redis sessions: which customers?
- Analytics/Experiments: which customers?
- Custom starter URL: which customers?
- Telemetry: which customers?
- Backup/restore capability: which customers?

### Step 5: Drift Detection

Identify fields where a customer's value looks like it SHOULD match the convention but doesn't:
- Probe configs that are slightly different from the majority (typo? intentional?)
- Security settings that are weaker than the majority (DOT_COOKIES_HTTP_ONLY=false when most are true)
- Resource allocations that seem misconfigured (requests > limits, very low memory for high heap)
- Missing PDBs for customers with replicas > 1
- Preferred anti-affinity for customers with replicas > 1 (should be required)

### Step 6: Complexity Assessment

Count the total number of distinct parameters needed to fully describe a customer:
- How many fields are in the "required parameter" category?
- How many are in the "optional feature" category?
- What is the minimum values file size needed for the simplest customer?
- What is the maximum for the most complex customer?

This directly informs whether the problem is "parameterization" (Helm territory) or "modeling" (cdk8s territory).

## Output Schema

Produce three files:

### `outputs/conventions/patterns.json`

```json
{
  "analysisDate": "ISO 8601",
  "totalCustomers": 84,
  "fields": {
    "{fieldPath}": {
      "category": "universal | universal_variable | common | minority | unique",
      "frequency": "number — count of customers with this field",
      "frequencyPct": "number — percentage",
      "distinctValues": "number",
      "mode": "most common value",
      "modePct": "percentage using the mode value",
      "distribution": { "value1": "count", "value2": "count" },
      "recommendedDefault": "value or null if no clear default",
      "parameterType": "hard_default | required | optional_with_default | customer_override"
    }
  },
  "namingConventions": {
    "statefulsetName": { "pattern": "string", "compliance": "percentage" },
    "serviceName": { "pattern": "string", "compliance": "percentage" },
    "pvcName": { "pattern": "string", "compliance": "percentage" },
    "secretName": { "pattern": "string", "compliance": "percentage" },
    "ingressHost": { "pattern": "string", "compliance": "percentage" }
  },
  "features": {
    "{featureName}": {
      "adoptionCount": "number",
      "adoptionPct": "percentage",
      "customers": ["list of customer names"]
    }
  }
}
```

### `outputs/conventions/defaults.json`

```json
{
  "analysisDate": "ISO 8601",
  "recommendedDefaults": {
    "{fieldPath}": {
      "value": "recommended default value",
      "confidence": "high | medium | low",
      "basedOn": "X out of Y customers use this value",
      "note": "any caveats"
    }
  },
  "requiredParameters": [
    {
      "field": "fieldPath",
      "description": "what this parameter controls",
      "exampleValues": ["from real customers"],
      "validationRule": "type constraint or regex"
    }
  ],
  "optionalParameters": [
    {
      "field": "fieldPath",
      "defaultValue": "value",
      "description": "what this controls",
      "whenToOverride": "guidance on when to change the default"
    }
  ]
}
```

### `outputs/conventions/anomalies.json`

```json
{
  "analysisDate": "ISO 8601",
  "drift": [
    {
      "customer": "name",
      "environment": "env name",
      "field": "fieldPath",
      "currentValue": "what they have",
      "expectedValue": "what the convention says",
      "severity": "info | warning | critical",
      "possibleReason": "best guess at why this differs",
      "recommendation": "align to convention | preserve as override | investigate"
    }
  ],
  "securityConcerns": [],
  "misconfigurations": [],
  "uniquePatterns": [
    {
      "customer": "name",
      "description": "what's unique about this customer",
      "fields": ["list of unique fields"],
      "recommendation": "how to handle in template"
    }
  ]
}
```

## Validation Criteria

1. **Coverage:** Every field from every customer discovery JSON is accounted for in the frequency analysis.
2. **Math:** Frequencies and percentages are arithmetically correct.
3. **Defaults:** Every recommended default has a confidence level and evidence.
4. **Drift:** Known issues (like TylerTech missing PDB, soft anti-affinity) appear in the anomalies.
5. **Complexity assessment:** The parameter count is realistic — not so low that customers can't be described, not so high that the template is over-parameterized.

## Exit Criteria

- All three output files exist and are valid JSON
- Every discovery JSON was processed (no customers skipped)
- The complexity assessment answers the "templating vs modeling" question with data
- Drift items include actionable recommendations
