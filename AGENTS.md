# AGENTS.md - Catalog Repository (CUE Definitions)

## Overview

Core OPM CUE definitions published as `opmodel.dev/core@v0`. Contains schemas for all definition types.

**⚠️ This project is under heavy development. APIs and schemas may change.**

## Constitution

This project follows the **Open Platform Model Constitution**.
All agents MUST read and adhere to `openspec/config.yaml`.

**Governance**: The constitution supersedes this file in case of conflict.

## Build/Test Commands

- Format: `task fmt` for all or `task fmt MODULE=<module name>` for one specific module
- Validate: `task vet` for all or `task vet MODULE=<module name>` for one specific module
- Download dependencies: `task tidy` for all or `task tidy MODULE=<module name>` for one specific module
- Print evaluation result: `task eval` for all or `task eval MODULE=<module name>` for one specific module. use `OUTPUT=<file>` to output to a file.
- Export schema: `cue export -e '#ModuleDefinition' v0/`

## Tone and style

- Be extremely concise - only output essential information
- No preamble or postamble
- Skip explanations unless asked
- Only show changed code, not entire files

## Code Style

- **Definitions**: Use `#` prefix (e.g., `#ResourceDefinition`, `#TraitDefinition`)
- **Hidden fields**: Use `_` prefix for internal/computed values
- **Required fields**: Use `!` suffix (e.g., `name!: string`)
- **Optional fields**: Use `?` suffix (e.g., `description?: string`)
- **Defaults**: Use `*` syntax (e.g., `port: *8080 | int`)

## OPM and CUE

Use these environment variables during development and validation. Commands like "cue mod tidy" or "cue vet ./..."

```bash
export OPM_REGISTRY='opmodel.dev=localhost:5000+insecure,registry.cue.works'
export CUE_REGISTRY='opmodel.dev=localhost:5000+insecure,registry.cue.works'
```

## Project Structure

```text
├── v0/                        # CUE module definitions
│   ├── core/                  # Core definitions (module, component, resource, trait, etc.)
│   ├── schemas/               # Shared schemas (common, network, workload, storage, etc.)
│   ├── resources/             # Resource implementations
│   │   ├── config/            # ConfigMap, Secret
│   │   ├── security/          # WorkloadIdentity
│   │   ├── storage/           # Volume
│   │   └── workload/          # Container
│   ├── traits/                # Trait implementations
│   │   ├── network/           # Expose, HTTPRoute, GRPCRoute, TCPRoute
│   │   ├── security/          # SecurityContext, Encryption
│   │   └── workload/          # Replicas, HealthCheck, ResourceLimit, etc.
│   ├── blueprints/            # Blueprint implementations
│   │   ├── data/              # SimpleDatabase
│   │   └── workload/          # Stateless, Stateful, Daemon, Task, ScheduledTask
│   ├── policies/              # Policy implementations
│   │   └── network/           # NetworkRules, SharedNetwork
│   ├── providers/             # Provider implementations
│   │   └── kubernetes/        # K8s provider + transformers
│   └── examples/              # Usage examples
├── openspec/                  # OpenSpec change management
│   ├── config.yaml            # Project constitution
│   └── changes/               # Active and archived changes
├── docs/                      # Documentation
└── README.md
```

## Git & Commits

Follow [Conventional Commits v1](https://www.conventionalcommits.org/en/v1.0.0/) and [Semantic Versioning v2.0.0](https://semver.org).

Format: `type(scope): description`
Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
Scope: module name when applicable (e.g., `feat(core): add X`)

No AI attribution in commit messages.

### Change-related commits

When a commit is related to an OpenSpec change, include the change name. Each phase CAN be a separate commit:

- **Creating a change**: `chore(openspec): add <change-name> change`
- **Implementing a change**: `feat(scope): implement <change-name> change`
  - Implementation includes a verification step before committing
- **Syncing & archiving a change**: `chore(openspec): archive <change-name> change`

## Glossary

See [full glossary](docs/glossary.md) for detailed definitions.

## Documentation Style

### Box-Drawing Diagrams and ASCII Art

**Symbols for Yes/No in Tables and Diagrams**

When creating box-drawing tables or ASCII art diagrams in markdown code blocks, use **monospace-safe** symbols that render consistently across all terminals, editors, and GitHub.

**DO NOT USE** Unicode checkmarks (`✓` U+2713, `✗` U+2717) — these are ambiguous-width characters that break alignment in monospace fonts.

**Recommended Replacements:**

| Context | Yes | No | Example |
|---------|-----|-----|---------|
| **Box-drawing table cells** | `[x]` | `[ ]` | `│ No CRDs req. │  [x]   │  [ ]   │` |
| **Bullet-style property lists** | `[x]` | `[ ]` | `│    [x] Same resources → same digest` |
| **Inline after text** | `OK` | `FAIL` | `Apply: SS/jellyfin-media OK, Svc/jellyfin-media FAIL` |
| **Section headings** | `[x]` | `[ ]` | `### Scenario A: Normal Rename [x]` |
| **Parenthetical notes** | `ok` | `fail` | `Label check: "opm" (3 ok), name (≤63 ok)` |

**Rationale:**

1. **`[x]` / `[ ]`** - Checkbox-style brackets are exactly 3 ASCII characters wide, easy to align in tables
2. **`OK` / `FAIL`** - More readable mid-sentence than brackets
3. **`ok` / `fail`** - Lowercase variant for lightweight inline use

**Table Alignment Example:**

```text
┌──────────────┬────────┬────────┬────────┐
│ Feature      │ Secret │ CRD    │ DB     │
├──────────────┼────────┼────────┼────────┤
│ No CRDs req. │  [x]   │  [ ]   │  [x]   │  ← 3 chars each, properly aligned
│ Inventory    │  [x]   │  [x]   │  [x]   │
└──────────────┴────────┴────────┴────────┘
```

**Why This Matters:**

- Unicode `✓` renders as 1 cell in some fonts, 2 cells in others (especially CJK locales)
- Broken alignment makes diagrams unreadable in terminals
- GitHub code blocks don't always match terminal rendering
- ASCII/bracket combinations are universally safe
