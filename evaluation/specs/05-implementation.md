# Spec 05: Implementation — Seed Customer Values Generation

## Context

Phase 4 produced a tool decision. This phase implements the chosen approach for 2-3 seed customers to validate that the theory works in practice. If Phase 4 recommended a dual-track comparison, both sub-specs (05a and 05b) execute in parallel.

## Skill

Load `platform-devops-architect` for Kubernetes and Helm/cdk8s domain expertise.

## Inputs

```
outputs/discovery/{seed-customer}.json       # Discovery data for seed customers
outputs/conventions/defaults.json            # Recommended defaults
outputs/gap-analysis/hardening.json          # Required chart fixes (if Helm)
decisions/adr-tool-selection.md              # Which tool to use
helm-charts/charts/dotcms/                   # Chart source (if Helm path)
```

## Seed Customer Selection Criteria

Select 2-3 customers from the discovery outputs:

1. **Simple baseline:** Fewest environments, minimal customization, standard resources
2. **Complex representative:** Multiple environments, custom cache sizes, optional features enabled (Glowroot, Redis, analytics)
3. **Edge case (optional):** A customer from the anomalies list that has unique characteristics

## Sub-Spec 05a: Helm Values Generation

### Task

For each seed customer:

1. **Apply chart hardening** from `gap-analysis/hardening.json`:
   - Fix identified bugs in the chart templates
   - Update defaults to match Phase 2 recommendations
   - Add any missing features needed for the seed customers

2. **Generate values file:**
   - Start with the customer's discovery JSON
   - Map each field to the chart's values structure
   - Only include fields that DIFFER from the chart's defaults
   - The values file should be as SMALL as possible (rely on defaults for everything standard)

3. **Document unmappable fields:**
   - Any field from the discovery that cannot be expressed in the current chart
   - Workarounds attempted
   - Whether `envVarsOverrides` or `customEnvVars` escape hatches were needed

### Output

```
outputs/implementation/helm/{customer}-values.yaml
outputs/implementation/helm/{customer}-mapping.json   # Field mapping documentation
```

## Sub-Spec 05b: cdk8s Construct Generation

### Task

For each seed customer:

1. **Design the construct hierarchy:**
   - Base construct: `DotcmsCustomer` with standard defaults
   - Feature addons: Linkerd, Prometheus, Glowroot, Redis
   - Configuration type: `CustomerConfig` with required and optional fields

2. **Implement the constructs:**
   - Generate TypeScript source files
   - Include type definitions matching the discovery schema
   - Implement rendering for all resources: StatefulSet, Service, Ingress, PDB, NetworkPolicies, RBAC, SecretProviderClass

3. **Generate customer config:**
   - Create a config file (TypeScript or JSON) for each seed customer
   - Only include fields that differ from construct defaults

4. **Run synth:**
   - Execute `cdk8s synth` to produce YAML output
   - Capture the output for Phase 6 comparison

### Output

```
outputs/implementation/cdk8s/src/                      # Source code
outputs/implementation/cdk8s/configs/{customer}.ts     # Customer configs
outputs/implementation/cdk8s/dist/{customer}/           # Generated YAML
outputs/implementation/cdk8s/{customer}-mapping.json   # Field mapping documentation
```

## Validation Criteria

1. **Values/config completeness:** Every field from the customer's discovery JSON is either:
   - Mapped to a chart/construct parameter, OR
   - Documented as unmappable with a workaround
2. **Minimality:** The values/config file only contains overrides, not defaults
3. **Correct mapping:** The mapping JSON shows every field's source and destination

## Exit Criteria

- Values/config files exist for all seed customers
- Mapping documentation is complete
- For cdk8s: synth runs without errors and produces YAML
- For Helm: `helm template` runs without errors
- Ready for Phase 6 diff validation
