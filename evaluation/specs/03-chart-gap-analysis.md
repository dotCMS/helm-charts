# Spec 03: Chart Gap Analysis — What Does the Chart Need?

## Context

Phase 2 produced the ground truth of what 84 customers actually need. This phase compares those requirements against the existing Helm chart (dotCMS/helm-charts v1.0.34) to identify what's missing, what's broken, and what needs hardening.

This is also where we assess whether the existing chart's architecture can EXPRESS all discovered patterns, or whether structural limitations would require a fundamentally different approach. This data directly feeds the Helm vs cdk8s decision in Phase 4.

## Skill

Load `engineering:code-review` for systematic code review methodology.
Load `platform-devops-architect` for Kubernetes and Helm domain expertise.

## Inputs

```
outputs/conventions/patterns.json
outputs/conventions/defaults.json
outputs/conventions/anomalies.json
helm-charts/charts/dotcms/           # The entire chart directory
```

## Task

### Step 1: Feature Coverage Mapping

For each required and optional parameter from `defaults.json`, determine:
- Does the chart have a corresponding values path?
- Does the template correctly render this field?
- Does the default match the recommended default from Phase 2?

Classify each as:
- **Covered:** Chart supports this field correctly
- **Covered, wrong default:** Chart supports this but default is wrong
- **Partially covered:** Chart has the field but rendering is incomplete or buggy
- **Missing:** Chart has no support for this field
- **Unnecessary:** Chart supports something no customer actually uses

### Step 2: Template Logic Review

For each template file in `charts/dotcms/templates/`, evaluate:
- Does the rendering logic correctly handle all discovered patterns?
- Are there edge cases from the anomalies that would break the template?
- Are conditional features (Linkerd, Prometheus, Glowroot, Redis) correctly gated?
- Does the multi-environment merge helper (`myapp.mergeEnvironment`) correctly deep-merge all field types?

### Step 3: Bug Inventory

Document all bugs found in the chart, including but not limited to:
- Duplicate fields in YAML output
- Naming inconsistencies (myapp vs dotcms prefix)
- Template values that reference undefined paths
- Conditional logic that fails for edge cases
- Resource definitions missing required fields
- Deprecated Kubernetes API usage

### Step 4: Expressiveness Assessment

This is the CRITICAL step for the Helm vs cdk8s decision. Answer:

1. **Can every customer pattern be expressed as a values.yaml override?**
   - If YES → Helm is sufficient (problem is parameterization)
   - If NO → Document which patterns CANNOT be expressed and why

2. **How complex is the most complex customer's values file?**
   - Count lines needed
   - Count nesting depth
   - Assess readability

3. **Are there customers that need STRUCTURAL differences (not just value differences)?**
   - Different container specs?
   - Different volume configurations?
   - Different init container chains?
   - Custom sidecars?

4. **How maintainable is the _helpers.tpl?**
   - Current line count and trend
   - Number of distinct helper functions
   - Deepest nesting level in Go template logic
   - Cyclomatic complexity estimate (number of conditionals)

### Step 5: Hardening Recommendations

Based on Phase 2 defaults and the current chart state, produce specific recommendations:
- Default value changes (with before/after)
- Missing features to implement (with priority)
- Bugs to fix (with severity)
- Template refactoring opportunities

## Output Schema

### `outputs/gap-analysis/coverage.json`

```json
{
  "analysisDate": "ISO 8601",
  "chartVersion": "1.0.34",
  "summary": {
    "totalRequirements": "number",
    "covered": "number",
    "coveredWrongDefault": "number",
    "partiallyCovered": "number",
    "missing": "number",
    "unnecessary": "number"
  },
  "details": {
    "{fieldPath}": {
      "status": "covered | covered_wrong_default | partially_covered | missing | unnecessary",
      "chartPath": "values path in chart or null",
      "discoveredDefault": "from Phase 2",
      "chartDefault": "current chart default or null",
      "note": "explanation"
    }
  }
}
```

### `outputs/gap-analysis/bugs.json`

```json
{
  "bugs": [
    {
      "id": "BUG-001",
      "file": "template file path",
      "line": "line number or range",
      "severity": "critical | high | medium | low",
      "description": "what's wrong",
      "impact": "what happens if not fixed",
      "fix": "proposed fix description"
    }
  ]
}
```

### `outputs/gap-analysis/expressiveness.json`

```json
{
  "analysisDate": "ISO 8601",
  "verdict": "sufficient | borderline | insufficient",
  "reasoning": "paragraph explaining the verdict",
  "allPatternsExpressible": true,
  "unexpressiblePatterns": [
    {
      "pattern": "description",
      "customers": ["affected customers"],
      "workaround": "how to handle in Helm if possible",
      "cdk8sAdvantage": "how cdk8s would handle this better, if at all"
    }
  ],
  "complexityMetrics": {
    "simplestCustomerValuesLines": "number",
    "mostComplexCustomerValuesLines": "number",
    "averageValuesLines": "number",
    "helpersTplLines": "number",
    "helperFunctionCount": "number",
    "maxNestingDepth": "number",
    "conditionalCount": "number"
  },
  "structuralVariations": {
    "customContainerSpecs": ["customers if any"],
    "customVolumes": ["customers if any"],
    "customInitContainers": ["customers if any"],
    "customSidecars": ["customers if any"]
  }
}
```

### `outputs/gap-analysis/hardening.json`

```json
{
  "defaultChanges": [
    {
      "field": "values path",
      "current": "current default",
      "recommended": "new default",
      "reason": "based on Phase 2 data",
      "priority": "critical | high | medium | low"
    }
  ],
  "missingFeatures": [
    {
      "feature": "description",
      "customersAffected": "number",
      "implementationEffort": "trivial | small | medium | large",
      "priority": "critical | high | medium | low"
    }
  ],
  "refactoringOpportunities": [
    {
      "area": "what to refactor",
      "currentState": "what it looks like now",
      "proposedState": "what it should look like",
      "benefit": "why bother"
    }
  ]
}
```

## Validation Criteria

1. **Coverage completeness:** Every required/optional parameter from Phase 2 has a coverage status.
2. **Bug verification:** Each bug can be reproduced by examining the referenced file and line.
3. **Expressiveness:** The verdict is supported by concrete evidence (specific patterns that can or cannot be expressed).
4. **Hardening:** Every recommendation includes priority and affected customer count.

## Exit Criteria

- All four output files exist and are valid JSON
- The expressiveness verdict is one of: sufficient, borderline, insufficient
- If "insufficient," specific unexpressible patterns are documented with evidence
- Bug list includes all previously identified bugs from the chart review (rbac duplicates, naming inconsistency, etc.)
