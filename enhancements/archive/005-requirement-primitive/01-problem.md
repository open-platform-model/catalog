# Problem Statement — Requirements Primitive & Backup/Restore

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-28       |
| **Authors** | OPM Contributors |

---

## Current State

OPM's primitive taxonomy defines four types: Resource ("what exists"), Trait ("how it behaves"), Blueprint ("what is the pattern"), and PolicyRule ("what rules must be followed"). These cover the structural, behavioral, and governance dimensions of an application model.

However, there is no primitive for **operational contracts** — things a module needs the platform to do *for* it. Module authors can describe what their application is (Resources), how it should behave (Traits), and the platform team can mandate rules (PolicyRules). But the module author cannot declare "I need the platform to back up my data" or "here is how to restore me after failure" or "these components need shared networking."

This gap became concrete during backup/restore testing on kind-opm-dev (2026-03-28).

## Gap 1: Missing Primitive Category

The current taxonomy leaves a category unmodeled:

| Primitive | Question | Direction | Status |
|-----------|----------|-----------|--------|
| `#Resource` | "What must exist?" | Module author -> Component | Exists |
| `#Trait` | "How does it behave?" | Module author -> Component | Exists |
| `#Blueprint` | "What is the pattern?" | Module author -> Component | Exists |
| `#PolicyRule` | "What rules apply?" | Platform team -> Module | Exists |
| `???` | "What does this module need from the platform?" | Module author -> Platform | **Missing** |

Three alternative approaches were explored (PolicyRule, Hybrid Trait+PolicyRule, pure Trait) and each revealed the same mismatch:

- **PolicyRules** flow platform -> module (governance). Backup/restore flows module -> platform (operational need). Using PolicyRule inverts the ownership model.
- **Traits** configure the component itself (scaling, health checks). Backup/restore asks the platform to act *on behalf of* the component. The module doesn't consume backup configuration in its spec.
- **Hybrid** (Trait + PolicyRule) works mechanically but conflates two distinct concerns into existing primitives that don't quite fit either one.

See [04-approach-a-pure-policy.md](04-approach-a-pure-policy.md), [05-approach-b-hybrid.md](05-approach-b-hybrid.md), and [06-approach-c-pure-trait.md](06-approach-c-pure-trait.md) for the full exploration.

## Gap 2: Backup Duplication Across Modules

Each module that needs backup currently defines its own K8up-specific components directly in `components.cue`. The backup configuration schema (~20 lines) and K8up component definitions (~30 lines) are duplicated across modules.

Current modules with backup: Jellyfin (`modules/jellyfin/components.cue:238-313`) and Seerr (`modules/seerr/components.cue:230-284`). Both define nearly identical structures:

- K8up Schedule CR with S3 backend, retention, and cron schedules
- PreBackupPod CR with SQLite WAL checkpoint commands
- Inline K8up resource imports and schema references

Adding backup to a new module requires copying this boilerplate. Any improvements (new retention options, better hook handling) must be applied module by module.

## Gap 3: Restore Is Manual and Undocumented

Neither the current implementation nor the 004-backup-trait enhancement addresses restore. Today, restore is a fully manual `kubectl` procedure:

- **In-place restore:** 6 manual steps (scale down, write Restore CR YAML, apply, wait, scale up, verify)
- **Disaster recovery:** 12+ manual steps (recreate namespace, recreate secrets, create PVC with correct labels, apply Restore CR, wait, redeploy via OPM, verify)

This procedure is not encoded in the module definition. Each module's DR guide (`modules/jellyfin/DISASTER_RECOVERY.md`, `modules/seerr/DISASTER_RECOVERY.md`) was written by hand after testing.

## Gap 4: DR Requires Hidden Knowledge

Full disaster recovery requires knowing:

- Which secrets to recreate (and their data)
- The PVC name, size, and storage class
- That the PVC must be labeled `app.kubernetes.io/managed-by: open-platform-model` for OPM to adopt it
- Whether secrets also need the OPM management label (they do for OPM auto-created secrets)
- The health check endpoint to verify restore success

None of this is derivable from the module definition. It lives in operator memory or manual documentation.

## Gap 5: `#SharedNetwork` Is Misclassified

`#SharedNetwork` is currently modeled as a `#PolicyRule` composed into a `#Policy`. But it is written by the module author ("my components need to communicate"), not the platform team. It expresses a need, not a governance mandate.

```cue
// Current: SharedNetwork as a PolicyRule (governance direction: platform -> module)
#policies: {
    "internal-network": network.#NetworkRules & network.#SharedNetwork & {
        appliesTo: matchLabels: { "core.opmodel.dev/workload-type": "stateless" }
        spec: {
            networkRules: { ... }
            sharedNetwork: { ... }
        }
    }
}
```

This works mechanically but misrepresents ownership. The module author is using a platform-team primitive to express a module-level need.

## Concrete Example

On 2026-03-28, a backup and restore test battery was run on kind-opm-dev for Jellyfin and Seerr. The test included ad-hoc backups, in-place restores, and full disaster recovery (namespace deletion + restore + redeploy).

### What the operator had to do manually:

```bash
# In-place restore: 6 steps, must know workload name, PVC name, health endpoint
kubectl scale sts/jellyfin-jellyfin --replicas=0 -n jellyfin
kubectl apply -f restore.yaml    # 20 lines of hand-written K8up Restore CR YAML
kubectl wait --for=condition=completed restore/... -n jellyfin
kubectl scale sts/jellyfin-jellyfin --replicas=1 -n jellyfin
kubectl wait --for=condition=ready pod/jellyfin-jellyfin-0 -n jellyfin
kubectl exec ... -- curl -s http://localhost:8096/health
```

For disaster recovery, 12+ steps including recreating secrets, creating PVCs with OPM labels (discovered through trial and error when `opm release apply` failed), and running `opm release apply`.

### What should have happened:

```bash
opm release restore releases/kind_opm_dev/jellyfin/release.cue --snapshot 574dc25a
```

One command. The module declares a restore requirement. The CLI reads it and knows everything: the workload to scale, the PVC to target, the health check to run, the DR prerequisites to create.

## Why Existing Workarounds Fail

### Manual DR documentation

`DISASTER_RECOVERY.md` per module is not machine-readable, drifts from reality, must be independently maintained, and does not encode environment-specific differences.

### K8up Restore CRs applied manually

Operators must know S3 credentials, PVC names, scaling behavior, and the OPM label requirement. No health verification is built in.

### Enhancement 004 (backup trait)

Declares *what to protect* but not *how to recover*. The platform knows how to create backups but has no contract for executing restores. The CLI cannot offer `opm release restore` without a module-declared restore contract.

### Stretching existing primitives

Three approaches were explored (see appendix files). Each works mechanically but creates a semantic mismatch in the primitive taxonomy that will compound as more operational contracts are needed (DNS, certificates, database provisioning, storage provisioning).
