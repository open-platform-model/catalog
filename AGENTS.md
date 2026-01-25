# AGENTS.md - Core Repository (CUE Definitions)

## Overview

Core OPM CUE definitions published as `opm.dev/core@v0`. Contains schemas for all definition types.

## Build/Test Commands

- Format: `cue fmt ./...`
- Validate: `cue vet ./...`
- Export schema: `cue export -e '#ModuleDefinition' v0/`
- Check module: `cue mod tidy` (in v0/ directory)

## Tone and style

- Be extremely concise - only output essential information
- No preamble or postamble
- Skip explanations unless asked
- Only show changed code, not entire files

## Versioning

- **Follow [Semantic Versioning v2.0.0](https://semver.org) for all repositories.**
- **Follow [Conventional Commits v1](https://www.conventionalcommits.org/en/v1.0.0/) for all repositories.**

## Code Style

- **Definitions**: Use `#` prefix (e.g., `#ResourceDefinition`, `#TraitDefinition`)
- **Hidden fields**: Use `_` prefix for internal/computed values
- **Required fields**: Use `!` suffix (e.g., `name!: string`)
- **Optional fields**: Use `?` suffix (e.g., `description?: string`)
- **Defaults**: Use `*` syntax (e.g., `port: *8080 | int`)

## Project Structure

```text
├── v0/                # Core CUE definitions (opm.dev/core@v0)
│   ├── cue.mod/       # CUE module configuration
│   ├── module.cue     # ModuleDefinition, Module, ModuleRelease
│   ├── component.cue  # Component schema
│   ├── resource.cue   # ResourceDefinition schema
│   ├── trait.cue      # TraitDefinition schema
│   ├── blueprint.cue  # BlueprintDefinition schema
│   ├── policy.cue     # PolicyDefinition schema
│   ├── provider.cue   # ProviderDefinition schema
│   ├── scope.cue      # Scope schema
│   ├── transformer.cue # Transformer schema
│   └── common.cue     # Shared types (#NameType, #FQNType, etc.)
├── docs/              # Documentation
└── README.md
```

## Maintenance Notes

- **Project Structure Tree**: Update the tree above when adding new CUE files or directories.

## Key Files

- `v0/module.cue` - ModuleDefinition, Module, ModuleRelease schemas
- `v0/resource.cue` - ResourceDefinition schema
- `v0/trait.cue` - TraitDefinition schema
- `v0/component.cue` - ComponentDefinition schema
- `v0/common.cue` - Shared types (#NameType, #FQNType, #VersionType)

## Patterns

- FQN format: `"{apiVersion}#{name}"` (e.g., `"opm.dev/core@v1#Container"`)
- Function pattern: `#Func: {X1="in": {...}, out: {...}}`
- Closed definitions: Use `close({...})` to prevent extra fields

## Glossary

See [full glossary](../opm/docs/glossary.md) for detailed definitions.

### Personas

- **Infrastructure Operator** - Operates underlying infrastructure (clusters, cloud, networking)
- **Module Author** - Develops and maintains ModuleDefinitions with sane defaults
- **Platform Operator** - Curates module catalog, bridges infrastructure and end-users
- **End-user** - Consumes modules via ModuleRelease with concrete values
