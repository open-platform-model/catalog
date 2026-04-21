# Istio OPM resources

## Summary

CUE schemas + OPM `#Resource` / `#Component` wrappers for Istio CRDs. Covers networking, security, telemetry, and extensions API groups (ambient + sidecar).

Types are generated from upstream CRDs via `timoni mod vendor crd`; resource wrappers expose them as first-class OPM authoring primitives usable by application modules.

## Contents

| Path | Description |
|---|---|
| `schemas/**/types_gen.cue` | Generated types, one file per CRD version. Carry a `//timoni:generate` marker. |
| `resources/network/` | VirtualService, DestinationRule, Gateway, Sidecar, ServiceEntry, EnvoyFilter, WorkloadEntry, WorkloadGroup, ProxyConfig |
| `resources/security/` | AuthorizationPolicy, PeerAuthentication, RequestAuthentication |
| `resources/observability/` | Telemetry |
| `resources/extension/` | WasmPlugin |
| `providers/kubernetes/` | Transformers registering each `#Resource` with the Kubernetes provider |
| `crds/version.yml` | Upstream Istio version + source URL |

## CRD source

Istio ships one combined CRD manifest in the `base` Helm chart:

```
https://raw.githubusercontent.com/istio/istio/<version>/manifests/charts/base/files/crd-all.gen.yaml
```

See `crds/version.yml` for the exact version vendored.

## Updating

1. Pick the target Istio version and set it in `crds/version.yml`.
2. Download the combined manifest:
   ```bash
   ISTIO_VER=1.28.3
   curl -L \
     "https://raw.githubusercontent.com/istio/istio/${ISTIO_VER}/manifests/charts/base/files/crd-all.gen.yaml" \
     -o crds/istio-all-crds.yaml
   ```
3. Regenerate CUE types:
   ```bash
   cd catalog/istio/v1alpha1
   timoni mod vendor crd -f crds/istio-all-crds.yaml
   ```
   timoni writes `schemas/<domain>/<api-group>/<kind>/<version>/types_gen.cue` for every CRD.
4. Review diffs; keep a `//timoni:generate` comment on every generated file.
5. Validate:
   ```bash
   cue vet ./...
   ```

## Links

- [Istio releases](https://github.com/istio/istio/releases)
- [Istio API reference](https://istio.io/latest/docs/reference/config/)
- [Ambient mesh](https://istio.io/latest/docs/ambient/)
