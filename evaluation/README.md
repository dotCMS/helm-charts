# Helm Chart Migration: Spec-Driven Evaluation Framework

## What Is This?

A structured framework for evaluating and migrating dotCMS customer Kubernetes manifests from hand-crafted YAML to a standardized template system. The evaluation is tool-agnostic — it collects evidence first, then uses that evidence to make an informed Helm vs cdk8s decision.

## How It Works

Each `specs/*.md` file is a contract that defines a discrete phase of work. An AI subagent (or human) reads the spec, executes the task, and produces structured output. Each phase's output feeds the next phase.

```
specs/00-pipeline.md          ← Start here. Orchestration overview.
specs/01-customer-discovery.md ← Per-customer YAML analysis
specs/02-convention-extraction.md ← Cross-customer pattern mining
specs/03-chart-gap-analysis.md ← Chart vs requirements comparison
specs/04-tool-decision.md      ← Evidence-based Helm vs cdk8s ADR
specs/05-implementation.md     ← Seed customer implementation
specs/06-diff-validation.md    ← Provable equivalence testing
```

## Running a Spec

To execute a spec with a Claude subagent:

1. Read the spec file
2. Load the skill(s) specified in the spec
3. Read the input files
4. Execute the task
5. Produce output in the exact schema defined
6. Self-validate against the criteria

## Directory Structure

```
evaluation-framework/
├── README.md                  ← This file
├── specs/                     ← Phase contracts (read-only during execution)
│   ├── 00-pipeline.md
│   ├── 01-customer-discovery.md
│   ├── 02-convention-extraction.md
│   ├── 03-chart-gap-analysis.md
│   ├── 04-tool-decision.md
│   ├── 05-implementation.md
│   └── 06-diff-validation.md
├── outputs/                   ← Structured results from each phase
│   ├── discovery/             ← Per-customer JSON (Phase 1)
│   ├── conventions/           ← Cross-customer analysis (Phase 2)
│   ├── gap-analysis/          ← Chart evaluation (Phase 3)
│   ├── implementation/        ← Values files / cdk8s configs (Phase 5)
│   └── validation/            ← Diff reports (Phase 6)
└── decisions/                 ← ADRs (Phase 4, 7)
```

## Methodology

Based on Steve Bolton's "provable refactoring" approach:

> Use the 84 existing customer manifests as the test suite. If the template
> system produces functionally equivalent YAML for every customer, the
> migration is provably correct.

The framework extends this with spec-driven agent orchestration, where each phase has explicit inputs, outputs, and validation criteria that enable autonomous execution.
