# opm_experiments

Experimental primitives, traits, directives, and transformers.

## Purpose

Sandbox for in-flight catalog work that is not ready for `opm/v1alpha1`.
Definitions here may change shape, be renamed, or be removed without notice.

## Stability

- **No stability guarantee.** Pin to an exact version.
- Graduation criteria: validated against at least two modules, reviewed, then promoted to `opm/v1alpha1`.

## Layout

```
directives/   Experimental #Directive definitions (e.g., K8up backup)
traits/       Experimental #Trait definitions
providers/
  kubernetes/
    transformers/   Experimental transformers consuming the above
```

## Current experiments

- Enhancement 009 (`catalog/enhancements/009-backup-directive/`) — K8up backup + restore directive.
