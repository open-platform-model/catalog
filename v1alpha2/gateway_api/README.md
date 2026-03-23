# Gateway API CUE Module

## Summary

CUE type definitions for Kubernetes Gateway API resources, imported from the official CRDs and refined with explicit constraints. This module is a dependency of the `opm/` catalog module — transformers import these types to validate their output manifests.

## Contents

| Path | Description |
|---|---|
| `v1/types.cue` | GA resource types: `#Gateway`, `#HTTPRoute`, `#GRPCRoute`, `#TLSRoute`, `#ReferenceGrant`, `#BackendTLSPolicy`, `#ListenerSet` |
| `v1alpha2/types.cue` | Experimental resource types: `#TCPRoute`, `#UDPRoute` |
| `crds/experimental-install.yaml` | Source CRD YAML downloaded from the Gateway API release |
| `version.yml` | CRD version and download metadata |
| `PLAN.md` | Research reference: resource inventory, Istio integration, cert-manager integration, import methodology |

## CRD Source

Types are generated from the Gateway API experimental channel CRDs. The experimental channel is a strict superset of the standard channel — it contains all GA resources plus the alpha resources.

See `version.yml` for the exact version and download URL. See `PLAN.md` for full research notes.

## Updating

To update to a newer Gateway API version:

1. Download the new experimental CRDs:
   ```
   curl -L -o crds/experimental-install.yaml \
     https://github.com/kubernetes-sigs/gateway-api/releases/download/<version>/experimental-install.yaml
   ```
2. Re-run the import:
   ```
   cue import -p gatewayapi -f --list crds/experimental-install.yaml
   ```
3. Review the diff and apply manual constraint refinements as needed
4. Update `version.yml` with the new version and date
5. Validate: `cue vet ./...`

## Links

- [Gateway API specification](https://gateway-api.sigs.k8s.io/)
- [GitHub releases](https://github.com/kubernetes-sigs/gateway-api/releases)
