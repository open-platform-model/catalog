# AGENTS.md - Catalog Repository (CUE Definitions)

## Overview

Core OPM CUE definitions published as `opmodel.dev/core@v0`. Contains schemas for all definition types.

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
export CUE_REGISTRY=localhost:5000
export OPM_REGISTRY=localhost:5000
export CUE_CACHE_DIR=/var/home/emil/Dev/open-platform-model/.cue-cache
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
