# Spec 06: Diff Validation — Provable Equivalence Testing

## Context

This is Steve Bolton's "provable refactoring" step. The implementation from Phase 5 claims to reproduce customer manifests. This phase PROVES it by comparing the generated output against the actual production YAML, normalized for cosmetic differences.

A clean diff means the implementation correctly captures the customer's deployment logic. A non-empty diff must be classified as either a known improvement (intentional change) or a regression (bug in the implementation).

## Skill

Load `engineering:testing-strategy` for test methodology.
Load `platform-devops-architect` for Kubernetes semantic understanding.

## Inputs

```
# For Helm path:
outputs/implementation/helm/{customer}-values.yaml
helm-charts/charts/dotcms/

# For cdk8s path:
outputs/implementation/cdk8s/dist/{customer}/

# Ground truth:
infrastructure-as-code/kubernetes/customers/{customer}/{env}/statefulset.yaml
infrastructure-as-code/kubernetes/customers/{customer}/{env}/alb.yaml
infrastructure-as-code/kubernetes/customers/{customer}/{env}/services.yaml
infrastructure-as-code/kubernetes/customers/{customer}/namespace/**/*.yaml
```

## Task

### Step 1: Generate Output

**Helm:**
```bash
helm template dotcms helm-charts/charts/dotcms/ \
  -f outputs/implementation/helm/{customer}-values.yaml \
  --output-dir outputs/validation/{customer}/generated/
```

**cdk8s:**
Copy from `outputs/implementation/cdk8s/dist/{customer}/`

### Step 2: Normalize Both Sides

Apply normalization to BOTH the generated output AND the original YAML:

1. **Parse YAML** into structured objects (handle multi-document files)
2. **Sort keys** alphabetically at every level
3. **Sort lists** where order is not semantically significant:
   - Environment variables: sort by name
   - Labels: sort by key
   - Annotations: sort by key
   - Ports: sort by name or containerPort
   - Volume mounts: sort by mountPath
   - NOTE: Container order in `containers[]` IS significant — preserve it
   - NOTE: Init container order IS significant — preserve it
4. **Normalize values:**
   - Quote consistency: `'true'` vs `"true"` vs `true` → normalize to unquoted where valid
   - Number formatting: `"8080"` vs `8080` → normalize to appropriate type
   - Whitespace: trim trailing whitespace, normalize indentation to 2 spaces
5. **Strip non-functional content:**
   - Comments
   - Empty lines
   - Helm-specific labels (helm.sh/chart, app.kubernetes.io/managed-by) from generated side only
6. **Split multi-resource files** into one file per resource, named by `kind-name.yaml`

### Step 3: Resource-Level Diff

For each Kubernetes resource (identified by kind + namespace + name):

1. Match the resource between generated and original
2. Compute a semantic diff (not textual — understand YAML structure)
3. Classify each diff line:

| Classification | Meaning | Action |
|---|---|---|
| **cosmetic** | Formatting, ordering, quoting differences | Ignore |
| **improvement** | Chart adds something the original lacks (PDB, hard anti-affinity, better defaults) | Document as intentional improvement |
| **equivalent** | Different representation, same K8s effect (e.g., `cpu: '8'` vs `cpu: 8`) | Ignore |
| **regression** | Generated output is missing something the original has | BUG — must fix |
| **addition** | Generated output has something the original lacks that's NOT an improvement | Investigate — may be chart default that should be suppressed |

### Step 4: Summary Report

Aggregate results across all resources and environments for the customer.

## Output Schema

### Per-environment diff: `outputs/validation/{customer}-{env}.diff`

```
# Diff Report: {customer} / {env}
# Generated: {timestamp}
# Tool: helm | cdk8s

## StatefulSet: {name}
Status: CLEAN | DIFFS_FOUND

### Cosmetic (ignored): {count}
### Improvements: {count}
{list of improvements with explanation}

### Regressions: {count}
{list of regressions with details}

### Additions to investigate: {count}
{list with explanation}
```

### Summary: `outputs/validation/summary.json`

```json
{
  "validationDate": "ISO 8601",
  "tool": "helm | cdk8s | both",
  "customers": {
    "{customer}": {
      "environments": {
        "{env}": {
          "resources": {
            "{kind}-{name}": {
              "status": "clean | improvements_only | regressions_found",
              "cosmetic": "number",
              "improvements": "number",
              "regressions": "number",
              "additions": "number"
            }
          },
          "overallStatus": "clean | improvements_only | regressions_found"
        }
      },
      "overallStatus": "clean | improvements_only | regressions_found",
      "regressionCount": "total across all envs",
      "improvementCount": "total across all envs"
    }
  },
  "globalSummary": {
    "totalResources": "number",
    "cleanResources": "number",
    "resourcesWithImprovementsOnly": "number",
    "resourcesWithRegressions": "number",
    "overallVerdict": "PASS | PASS_WITH_IMPROVEMENTS | FAIL"
  }
}
```

## Validation Criteria

1. **Every resource compared:** No resource in the original is skipped.
2. **Classification accuracy:** Each diff line is correctly classified (spot-check at least 5).
3. **Zero false negatives:** No regression is classified as cosmetic.
4. **Improvements documented:** Every "improvement" has a justification referencing the hardening recommendations.

## Exit Criteria

- Diff reports exist for every seed customer environment
- Summary JSON is valid and complete
- If any regressions exist: they are documented with root cause
- Overall verdict is one of: PASS, PASS_WITH_IMPROVEMENTS, or FAIL
- If FAIL: the regressions are fed back to Phase 5 for fixing (iterate)
