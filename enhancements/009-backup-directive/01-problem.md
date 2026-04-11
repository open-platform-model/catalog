# Problem Statement — `#Directive` Primitive: Backup & Restore

## Current State

Backup support in OPM is implemented per-module with high duplication. Each module that needs backup defines an identical `backup?:` config schema (~20 lines), conditional K8up Schedule and PreBackupPod components (~30 lines), and direct K8up catalog imports. Jellyfin and Seerr demonstrate this — identical backup structures, identical boilerplate.

Restore is entirely manual. A 12+ step `kubectl` procedure involving workload scale-down, K8up Restore CR creation, status monitoring, label reapplication, and health verification. The platform has no model for what "restore this module" means.

## Problem 1: Component-Level Scope Mismatch

Enhancement 004 addressed duplication with component-level traits (`#BackupTrait`, `#PreBackupHookTrait`). The traits attach to individual components and the transformer generates K8up resources. This works mechanically but misrepresents the concern:

- Backup is a **module-level decision** — the module author decides which components need protection and how they coordinate during restore
- Component-level traits cannot express cross-component restore ordering ("restore the database before the app")
- The responsibility split is unclear: the trait attaches to a component, but the backup policy spans the module

The module author thinks about backup as "protect this module's data." The component-level model forces them to think about "protect this specific component" — a different, narrower concern.

## Problem 2: Enhancement 006 Complexity

Enhancement 006 proposed a comprehensive solution: `#Claim` (component-level, Blueprint-composable) for declaring needs, and `#Orchestration` (module-level in `#Policy`) for cross-component coordination. This design is sound but introduces:

- A new component-level primitive (`#Claim`) with Blueprint composition changes
- A second rendering pipeline independent from the trait pipeline
- CUE late-binding questions for data claim fulfillment
- The full `#Offer` system (enhancement 007) as a companion requirement

For the backup/restore use case specifically, this is overengineered. Backup does not need Blueprint composition (`#BackedUpStatefulWorkload` is a theoretical pattern, not a demonstrated need). Backup does not need a separate rendering pipeline. Backup needs a way to describe "what, where, when" at the module level and have the platform act on it.

## Problem 3: PolicyRule Semantic Mismatch

The existing `#PolicyRule` carries enforcement semantics:

```cue
enforcement!: {
    mode!: "deployment" | "runtime" | "both"
    onViolation!: "block" | "warn" | "audit"
}
```

Backup is not governance. There is no "violation" when a backup runs or doesn't run. There is no "block" or "warn" semantic. Forcing backup into `#PolicyRule` would require meaningless enforcement fields, confusing the distinction between governance and operations.

## Problem 4: No CLI Discovery

The CLI has no way to discover what a module declares about its backup/restore needs. Without a structured description in the module definition, the CLI cannot:

- List which components have backup configured
- Browse backup snapshots using the module's storage backend
- Execute a restore procedure based on the module's restore requirements (scale-down, health check, ordering)

## What Is Needed

A module-level primitive that:

1. Describes operational behavior (not governance) within `#Policy`
2. Carries no enforcement semantics
3. Can be read by transformers to generate platform resources (K8up Schedule, PreBackupPod)
4. Can be read by the CLI to execute operations (browse snapshots, restore)
5. Separates provider-specific backup (K8up, Velero) from provider-agnostic restore (CLI)
6. Includes restore description from the start
