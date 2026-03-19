# Spec 00: Master Pipeline — Spec-Driven Evaluation Framework

## Purpose

This is the orchestration spec. It defines the execution order, dependencies between phases, and the contract each spec must fulfill. Any agent starting work on any phase MUST read this spec first to understand where its work fits in the pipeline.

## Design Principles

1. **Tool-agnostic discovery.** Phases 1-3 produce structured data about what exists today. This data feeds ANY implementation tool (Helm, cdk8s, Kustomize, or something else). The tool decision comes AFTER the data is collected.

2. **Provable extraction.** Every claim about "what customers need" must be backed by evidence from the actual YAML in `infrastructure-as-code/kubernetes/customers/`. No assumptions. No tribal knowledge. Only what the manifests prove.

3. **Spec as contract.** Each spec.md defines inputs, task, output schema, validation criteria, and the skill/expertise required. An agent receiving a spec should be able to execute it autonomously without additional context.

4. **Incremental confidence.** Each phase builds on the previous one. No phase starts until its input dependencies are validated. The team can stop at any phase and still have valuable artifacts.

## Pipeline Overview

```
Phase 1: Discovery (per-customer)
    ├── spec-01: Customer Manifest Analysis
    │   skill: platform-devops-architect
    │   input: raw YAML from infrastructure-as-code repo
    │   output: outputs/discovery/{customer}.json
    │
    └── Can run in PARALLEL for all 84 customers

Phase 2: Convention Extraction (cross-customer)
    ├── spec-02: Pattern Analysis
    │   skill: engineering:tech-debt
    │   input: ALL outputs/discovery/*.json
    │   output: outputs/conventions/patterns.json
    │           outputs/conventions/defaults.json
    │           outputs/conventions/anomalies.json
    │
    └── DEPENDS ON: Phase 1 complete for ALL customers

Phase 3: Gap Analysis (chart evaluation)
    ├── spec-03: Chart Capability Assessment
    │   skill: engineering:code-review + platform-devops-architect
    │   input: outputs/conventions/*.json + helm-charts repo
    │   output: outputs/gap-analysis/helm-gaps.json
    │           outputs/gap-analysis/chart-bugs.json
    │           outputs/gap-analysis/hardening-recommendations.json
    │
    └── DEPENDS ON: Phase 2 complete

Phase 4: Tool Decision (human + AI advisory)
    ├── spec-04: Implementation Approach ADR
    │   skill: engineering:architecture
    │   input: outputs/gap-analysis/*.json + outputs/conventions/*.json
    │   output: decisions/adr-tool-selection.md
    │
    └── DEPENDS ON: Phase 3 complete
    └── NOTE: This is where Helm vs cdk8s is decided WITH DATA

Phase 5: Implementation (seed customers)
    ├── spec-05a: Helm Values Generation (if Helm chosen)
    │   OR
    ├── spec-05b: cdk8s Construct Generation (if cdk8s chosen)
    │   OR
    ├── spec-05c: BOTH in parallel (for side-by-side comparison)
    │   skill: platform-devops-architect
    │   input: outputs/discovery/{seed-customer}.json + conventions
    │   output: outputs/implementation/{tool}/{customer}-values.yaml
    │
    └── DEPENDS ON: Phase 4 decision

Phase 6: Diff Validation
    ├── spec-06: Provable Equivalence Testing
    │   skill: engineering:testing-strategy
    │   input: implementation outputs + original YAML
    │   output: outputs/validation/{customer}-{env}.diff
    │           outputs/validation/summary.json
    │
    └── DEPENDS ON: Phase 5 complete for target customers

Phase 7: Migration Readiness (future)
    ├── spec-07: Cutover Plan & Rollback ADR
    │   skill: engineering:architecture + platform-devops-architect
    │   input: validation results + ArgoCD configuration
    │   output: decisions/adr-migration-strategy.md
    │
    └── DEPENDS ON: Phase 6 shows clean diffs
```

## Execution Model

### Agent Autonomy

Each spec is designed for a subagent to execute independently. The agent:

1. Reads the spec
2. Reads any referenced skill files for domain expertise
3. Reads the input files specified in the spec
4. Produces output in the exact schema defined
5. Self-validates against the spec's validation criteria
6. Reports completion with a summary of findings

### Parallelism

- Phase 1 specs can run in parallel (one agent per customer or per batch)
- Phase 5c (dual-track) can run Helm and cdk8s agents in parallel
- All other phases are sequential

### Repositories

- **Source of truth (read-only):** `infrastructure-as-code/kubernetes/customers/`
- **Chart under evaluation (read-only initially):** `helm-charts/charts/dotcms/`
- **Evaluation workspace (write):** This directory (`evaluation-framework/`)

## Spec Contract Format

Every spec in this framework follows this structure:

```markdown
# Spec NN: Title

## Context
Why this phase exists and what question it answers.

## Skill
Which skill(s) the executing agent should load for domain expertise.

## Inputs
Exact file paths or glob patterns the agent needs to read.

## Task
Step-by-step instructions for what the agent must do.

## Output Schema
Exact JSON/YAML/Markdown structure the agent must produce.

## Validation Criteria
How the agent (or a reviewer) verifies the output is correct.

## Exit Criteria
What "done" means for this spec.
```
