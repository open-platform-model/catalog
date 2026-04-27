# Open Platform Model Catalog Constitution

## Purpose

This document is the reader-friendly reference for the principles that shape design, implementation, validation, and change management in the Open Platform Model catalog. The catalog is governed by the normative constitutional source in `openspec/config.yaml`.

## Design Principles

| # | Principle | Summary |
|---|-----------|---------|
| **I** | [Type Safety First](#i-type-safety-first) | Invalid configuration is rejected at definition time in CUE |
| **II** | [Separation of Concerns](#ii-separation-of-concerns) | Developers, platform teams, and consumers have distinct ownership boundaries |
| **III** | [Composability](#iii-composability) | Resources, Traits, and Blueprints compose without implicit coupling |
| **IV** | [Declarative Intent](#iv-declarative-intent) | Definitions express WHAT, not HOW |
| **V** | [Portability by Design](#v-portability-by-design) | Definitions stay declarative; runtime concerns live in providers |
| **VI** | [Semantic Versioning](#vi-semantic-versioning) | Artifacts use SemVer and commits use Conventional Commits |
| **VII** | [Simplicity & YAGNI](#vii-simplicity--yagni) | Complexity must be justified; prefer direct, composable solutions |
| **VIII** | [Self-Describing Distribution](#viii-self-describing-distribution) | CUE structure carries dependency, schema, and compatibility information |
| **IX** | [Small Batch Sizes](#ix-small-batch-sizes-iterative--incremental-delivery) | Changes must stay tiny, incremental, and independently verifiable |

---

### I. Type Safety First

All definitions MUST be expressed in CUE. Invalid configuration MUST be rejected at definition time, never in production. CUE's structural typing, constraints, and validation provide compile-time guarantees that prevent runtime failures.

- Structural typing and constraints catch invalid values early
- Closed structs and schema boundaries prevent silent drift and typos
- Cross-field validation keeps relationships correct before deployment
- Validation should fail in definition time rather than at runtime

```cue
#ScalingSchema: {
    count!: int & >=0 & <=1000
    cpu?:   int & >=0 & <=100
}
```

---

### II. Separation of Concerns

The delivery flow MUST maintain clear ownership boundaries:

- Developers declare intent via Modules
- Platform teams extend definitions via CUE unification
- Consumers receive approved ModuleReleases with concrete values

Module -> ModuleRelease is the canonical flow.

```text
Developer: Module            What the application needs
Platform:  Policy/Provider   How it is governed and deployed
Consumer:  ModuleRelease     Concrete values for a real environment
```

Each layer has a different responsibility and should evolve independently without breaking the others.

---

### III. Composability

Definitions MUST compose without implicit coupling:

- Resources describe what exists independently
- Traits modify behavior without knowing Resource internals
- Blueprints compose Resources and Traits without requiring modification
- Components reference definitions by name, not by internal structure

Composition happens through CUE unification, not hidden runtime wiring. This keeps definitions modular, testable, and safe to combine.

---

### IV. Declarative Intent

Modules MUST express intent, not implementation. Declare WHAT, not HOW.

- No imperative scripts in definitions
- No ordering dependencies between Resources unless explicitly modeled via Lifecycle
- No runtime-specific API calls in application definitions
- Provider-specific steps belong in ProviderDefinitions, applied at deployment time

This keeps modules portable, reviewable, and predictable under evaluation.

---

### V. Portability by Design

Definitions MUST stay declarative and decoupled from runtime details. Provider-specific concerns belong in ProviderDefinitions, so any provider that implements the catalog's primitives can render a module without the module being rewritten.

- Application definitions use OPM primitives, not platform-specific resource types
- Provider implementations translate those primitives to platform-specific output
- Portability is achieved by keeping platform details out of modules

The goal is to keep modules independent of runtime details. Feature parity across providers is not promised — providers document the primitives they support.

---

### VI. Semantic Versioning

All artifacts MUST follow SemVer 2.0.0. All commits MUST follow Conventional Commits v1: `type(scope): description`.

Allowed commit types:

- `feat`
- `fix`
- `refactor`
- `docs`
- `test`
- `chore`

Versioning is how the catalog communicates compatibility, change risk, and upgrade expectations across published artifacts.

---

### VII. Simplicity & YAGNI

Start simple. Complexity MUST be justified with clear rationale. Prefer:

- Direct solutions over clever indirection
- Fewer concepts that compose well over many specialized concepts
- Explicit configuration over implicit convention

If complexity is introduced, it should solve a real problem, not a speculative one.

---

### VIII. Self-Describing Distribution

Published modules, bundles, and providers MUST be self-describing. All information required to deploy a distributable MUST be derivable from its CUE structure, not from external metadata, lock files, or runtime discovery.

- CUE imports are dependency declarations
- CUE types are schema contracts
- Computed FQNs are version pins
- Provider compatibility is derivable from transformer requirements and a module's resource or trait FQN set

The CUE evaluation graph is the dependency graph. This is the architectural foundation for why OPM is built on CUE.

---

### IX. Small Batch Sizes (Iterative & Incremental Delivery)

All changes MUST be kept tiny. Small, incremental, independently verifiable steps are required.

- If a request is too large, it must be split into smaller sequential tasks
- Tiny changes produce focused, atomic commits
- A single commit should ideally address one specific concern

This principle applies to both implementation and planning. Large bundled changes hide risk, slow review, and weaken validation.

### Execution Gate

Before beginning any implementation, the scope of the request MUST be evaluated against the small-batch principle.

If the request is too large, the required response is:

> "🛑 **Scope Warning**: This request is too large for a single safe iteration. I suggest we split it into the following smaller steps: [list 2-3 logical, tiny steps]. Should we start with step 1?"

---

## Quality Gates

Before merge, the expected validation gates are:

1. `task fmt`
2. `task vet`
3. `task test`

## How Principles Work Together

These principles reinforce each other:

- Type safety supports composition, portability, and self-describing artifacts
- Separation of concerns keeps modules declarative and portable
- Composability enables simple, reusable definitions
- Declarative intent makes validation and provider translation reliable
- Small batch sizes keep change quality high and validation practical

When principles appear to conflict, treat that as a design smell and document the trade-off explicitly.

## Further Reading

- `openspec/config.yaml` — normative constitutional source
- `docs/design-principles.md` — expanded explanatory documentation
- `AGENTS.md` — repository mechanics, commands, and coding guidance
