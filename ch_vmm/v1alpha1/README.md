# ch-vmm OPM resources

## Summary

OPM resource + transformer definitions for the 9 `cloudhypervisor.quill.today/v1beta1` custom resources shipped by [ch-vmm](https://github.com/nalajala4naresh/ch-vmm) (Cloud Hypervisor Kubernetes add-on).

Pure passthrough: transformers emit native CRs with OPM name prefix, namespace, and labels applied; specs are copied verbatim. Typed specs are vendored from upstream CRDs with `timoni mod vendor crd` — downstream consumers get full CUE field-level validation.

This module does **not** deploy ch-vmm itself. Install the controller / daemon / CRDs separately (see `modules/ch_vmm/` in this workspace).

## Contents

| Path | Description |
|---|---|
| `resources/workload/*.cue` | 9 OPM `#Resource` wrappers — `#VirtualMachine`, `#VirtualDisk`, `#VirtualDiskSnapshot`, `#VirtualMachineMigration`, `#VMPool`, `#VMRestoreSpec`, `#VMRollback`, `#VMSet`, `#VMSnapShot` |
| `providers/kubernetes/` | `#Provider` + 9 passthrough transformers |
| `schemas/ch-vmm/cloudhypervisor.quill.today/*/v1beta1/types_gen.cue` | Timoni-generated CUE types from upstream CRDs. Do not edit by hand. |

## CRD Source

Schemas generated from the upstream release YAML:

- **Release**: [ch-vmm v1.4.0](https://github.com/nalajala4naresh/ch-vmm/releases/tag/v1.4.0)
- **URL**: `https://github.com/nalajala4naresh/ch-vmm/releases/download/v1.4.0/ch-vmm.yaml`
- **CRD API group**: `cloudhypervisor.quill.today`

## Regenerating schemas

The upstream release bundle ships CRDs inline with Deployment/RBAC/webhook manifests and duplicates each CRD (the second copy carries the `cert-manager.io/inject-ca-from` annotation). Extract the deduplicated CRD set before feeding it to timoni.

```bash
# 1. Download the release YAML
curl -sSL -o /tmp/ch-vmm-v1.4.0.yaml \
  https://github.com/nalajala4naresh/ch-vmm/releases/download/v1.4.0/ch-vmm.yaml

# 2. Split into per-CRD files and keep the first 9 (duplicates differ only in annotations)
yq ea '[.] | .[] | select(.kind == "CustomResourceDefinition")' /tmp/ch-vmm-v1.4.0.yaml \
  > /tmp/all_crds.yaml
csplit -sz -f /tmp/crd- -b '%02d.yaml' /tmp/all_crds.yaml '/^apiVersion: apiextensions/' '{*}'
yq ea '.' /tmp/crd-00.yaml /tmp/crd-01.yaml /tmp/crd-02.yaml \
  /tmp/crd-03.yaml /tmp/crd-04.yaml /tmp/crd-05.yaml \
  /tmp/crd-06.yaml /tmp/crd-07.yaml /tmp/crd-08.yaml \
  > /tmp/ch-vmm-crds-clean.yaml

# 3. Generate CUE schemas (timoni writes to cue.mod/gen/...)
cd catalog/ch_vmm/v1alpha1
timoni mod vendor crd -f /tmp/ch-vmm-crds-clean.yaml

# 4. Move generated files into the schemas/ tree
mv cue.mod/gen/cloudhypervisor.quill.today schemas/ch-vmm/
rmdir cue.mod/gen

# 5. Validate
cue vet ./...
cue vet -t test ./...
```

When upstream ships a new release, bump the version tag above and re-run these steps.

## Links

- [ch-vmm repository](https://github.com/nalajala4naresh/ch-vmm)
- [Cloud Hypervisor](https://www.cloudhypervisor.org/)
- [Timoni mod vendor crd docs](https://timoni.sh/cue-schemas/)
