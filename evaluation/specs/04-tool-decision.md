# Spec 04: Tool Decision — Architecture Decision Record

## Context

Phases 1-3 collected evidence. This phase uses that evidence to make the Helm vs cdk8s decision. This is NOT a theoretical comparison — it is a data-driven ADR that references specific findings from the discovery, convention extraction, and gap analysis.

The team must be able to read this ADR and understand WHY a particular tool was chosen, with evidence they can verify.

## Skill

Load `engineering:architecture` for ADR methodology.
Load `platform-devops-architect` for platform strategy context.

## Inputs

```
outputs/conventions/patterns.json
outputs/conventions/defaults.json
outputs/gap-analysis/coverage.json
outputs/gap-analysis/expressiveness.json
outputs/gap-analysis/hardening.json
```

## Task

### Step 1: Compile Decision Criteria

Using the evidence from prior phases, evaluate both tools on these axes:

1. **Expressiveness fit:**
   - From `expressiveness.json`: Can ALL customer patterns be expressed?
   - If verdict is "sufficient" → Helm meets requirements
   - If verdict is "insufficient" → Document what cdk8s would solve that Helm can't

2. **Complexity reality check:**
   - From `patterns.json`: How many distinct parameters exist?
   - From `expressiveness.json`: What's the simplest/most complex values file?
   - Is this "parameterization" (dozens of values) or "modeling" (structural variation)?

3. **Migration cost:**
   - Helm: Fix bugs + harden defaults + generate values for 84 customers
   - cdk8s: Write constructs from scratch + build CI pipeline + generate configs for 84 customers
   - Estimate effort in person-weeks for each

4. **Operational integration:**
   - ArgoCD compatibility (native vs requires pipeline)
   - Team expertise (existing vs requires training)
   - Debugging workflow (helm template/diff vs cdk8s synth + manual inspection)
   - Rollback capability

5. **Long-term maintainability:**
   - What happens when the 85th customer is onboarded?
   - What happens when a global change is needed (new probe, new network policy)?
   - What happens when a new team member joins?

### Step 2: Write the ADR

Follow standard ADR format:

```markdown
# ADR: Kubernetes Manifest Generation Tool Selection

## Status
Proposed

## Context
[Summarize the problem: 84 customers, hand-crafted YAML, need for standardization]

## Decision Drivers
[List the criteria from Step 1 with evidence references]

## Considered Options
1. Helm chart (existing dotCMS/helm-charts v1.0.34)
2. cdk8s (new implementation)
3. Hybrid: Helm for standard customers, cdk8s for complex outliers

## Decision Outcome
[Chosen option with justification]

## Evidence Summary
[Reference specific data points from Phase 1-3 outputs]

## Consequences
### Positive
### Negative
### Risks and Mitigations

## Action Items
[Concrete next steps based on the decision]
```

### Step 3: Dissenting Opinion

Regardless of which tool is chosen, write a section documenting the strongest counter-argument. If Helm is chosen, document the best case for cdk8s. If cdk8s is chosen, document the best case for Helm. This ensures intellectual honesty and gives the team the full picture.

## Output Schema

### `decisions/adr-tool-selection.md`

Standard ADR markdown document with the structure above. Must include:
- At least 3 specific data references to Phase 1-3 outputs
- Effort estimates with assumptions stated
- A clear "go/no-go" recommendation
- The dissenting opinion section

## Validation Criteria

1. **Evidence-based:** Every claim references specific data from prior phases.
2. **Actionable:** The decision leads to concrete next steps.
3. **Balanced:** The dissenting opinion is genuinely strong, not a strawman.
4. **Verifiable:** A team member can trace each data reference back to its source.

## Exit Criteria

- ADR document exists at `decisions/adr-tool-selection.md`
- Decision is one of: Helm, cdk8s, or Hybrid
- At least one concrete next step is defined
- The team can read this document and make an informed decision
