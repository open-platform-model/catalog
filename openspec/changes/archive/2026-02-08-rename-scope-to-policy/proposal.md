## Why

The OAM community learned through KubeVela (v1.0→v1.9) that Scopes as a distinct construct added indirection without sufficient value — they were deprecated in favor of flat Policies on the Application. OPM's `#Scope` already functions as a policy application group (not an OAM-style scope), but retains the OAM name, causing conceptual confusion. Renaming `#Scope` → `#Policy` (construct) and `#Policy` → `#PolicyRule` (primitive) aligns OPM with industry learnings while preserving OPM's grouping model.

## What Changes

- **BREAKING**: Rename `#Policy` primitive → `#PolicyRule` (kind: `"PolicyRule"`)
- **BREAKING**: Rename `#Scope` construct → `#Policy` (kind: `"Policy"`)
- **BREAKING**: Rename `#Scope.#policies` field → `#Policy.#rules`
- **BREAKING**: Rename `#Module.#scopes` → `#Module.#policies`
- **BREAKING**: Rename `#ModuleRelease.scopes` → `#ModuleRelease.policies`
- **BREAKING**: Remove `#PolicyRule.metadata.target` field (only value was `"scope"`, now redundant)
- Enhance `#Policy.appliesTo` with `matchLabels` for label-based component selection
- Rename `#PolicyMap` → `#PolicyRuleMap`, `#ScopeMap` → `#PolicyMap`
- Update all downstream consumers: `v0/policies/network/` definitions, docs

## Capabilities

### New Capabilities

- `policy-rule-primitive`: Renamed primitive (`#PolicyRule`) — schema for governance rules, constraints, and enforcement configuration
- `policy-construct`: Renamed construct (`#Policy`) — groups PolicyRules, targets components via explicit references or label matching, unifies rule specs
- `policy-label-matching`: New `matchLabels` field on `#Policy.appliesTo` for label-based component selection

### Modified Capabilities

_(none — no existing specs affected)_

## Impact

- **CUE modules affected**: core, policies (direct changes); providers, blueprints, examples (if they reference Scope/Policy)
- **API**: MAJOR breaking change — all type names and field names change
- **SemVer**: MAJOR (breaks existing module definitions using `#scopes` or `#Policy`)
- **Docs**: `docs/core/primitives.md`, `docs/core/constructs.md`, `docs/core/definition-types.md`, `docs/core/interface-architecture-rfc.md` all reference Scope/Policy
- **File renames**: `v0/core/scope.cue` and `v0/core/policy.cue` need renaming to avoid collision
