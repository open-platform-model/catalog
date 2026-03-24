---
status: in-progress
phase: 10
updated: 2026-03-23
---

# Implementation Plan: v1alpha2 Catalog Extensions

## Goal

Add Gateway API and cert-manager support to the OPM catalog as standalone CUE extension modules under `catalog/v1alpha2/`, with corresponding OPM schemas, resources, traits, and transformers in `opm/` that allow modules to declare Gateway, Route, Certificate, and Issuer resources.

---

## Context & Decisions

| Decision                                                            | Rationale                                                                                                                                                          | Source                                                                                     |
| ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------ |
| Create new v1alpha2 API version                                     | Restructured layout separates OPM core (`opm/`), Gateway API types (`gateway_api/`), cert-manager types (`cert_manager/`), and future K8s native resources (`kubernetes/`) | User directive                                                                             |
| `gateway_api/` is its own folder, separate from `kubernetes/`           | Gateway API is a first-class concern and warrants isolation; `kubernetes/` is deferred                                                                               | User directive                                                                             |
| `kubernetes/` deferred                                                | Not in scope for this work — focus only on Gateway API and cert-manager                                                                                            | User directive                                                                             |
| Gateway API: `timoni mod vendor crd`                                  | Produces named sub-types (`#HTTPRouteSpec`, `#HTTPRouteRule`, etc.), proper `uint16 & >=1` port constraints, pinned `apiVersion`/`kind`; won 11/19 criteria vs 0 for `cue import` | `local/experiments/crd-import-test/RESULTS.md`                                               |
| Adopt timoni-generated names (Option B)                             | No re-export mapping layer needed; all consumers (transformers) are being written fresh — zero migration cost, cleaner long-term                                   | Session decision 2026-03-22                                                                |
| cert-manager: use `cue.dev/x/crd/cert-manager.io@v0`                 | Curated upstream CUE registry module with semantic versioning; superior to timoni vendoring for cert-manager specifically                                           | `https://registry.cue.works/cue.dev/x/crd/cert-manager.io`                                  |
| `version.yml` in each extension folder                                | Reproducible version tracking for external CRD sources                                                                                                             | User directive                                                                             |
| Detailed `PLAN.md` in each extension folder                           | Research reference document for future maintainers                                                                                                                 | User directive                                                                             |
| Use Gateway API experimental channel                                | Includes all GA resources plus TCPRoute — user wants both GA and experimental                                                                                      | `https://github.com/kubernetes-sigs/gateway-api/releases/tag/v1.5.1`                         |
| Replace `#IngressTransformer` with Gateway API route transformers     | Ingress is legacy; the cluster runs Gateway API natively                                                                                                           | User decision                                                                              |
| Include Issuer and ClusterIssuer resources                          | Not deferred — cert-manager issuers are first-class OPM resources                                                                                                  | User decision                                                                              |
| Add TLSRoute support                                                | TLSRoute reached GA (v1) in Gateway API v1.5.0                                                                                                                     | User decision + `https://github.com/kubernetes-sigs/gateway-api/releases/tag/v1.5.0`         |
| `x-kubernetes-*` extensions may break OpenAPI import mode             | Use plain YAML import mode, not `cue import openapi`                                                                                                                 | GitHub issue `cue-lang/cue#2691`                                                             |
| cert-manager integrates with Gateway via annotations                | `cert-manager.io/cluster-issuer` on a Gateway triggers automatic Certificate creation per TLS listener                                                               | `https://cert-manager.io/docs/usage/gateway/`                                                |
| `#RouteAttachmentSchema` already has `gatewayRef`                       | Existing route schemas are partially Gateway API-ready — only transformer replacement is needed, not schema changes                                                | `opm/schemas/network.cue:93–107`                                                             |
| Include `GatewayClass` and `BackendTrafficPolicy` as full OPM resources | Both need type definitions in `gateway_api/` AND deployable OPM schemas/resources/transformers in `opm/` — not just types                                              | User directive (Option A confirmed)                                                        |
| Rename `modules/gateway_api/` to `modules/gateway/`                    | Shorter, cleaner name; `gateway_api` is the catalog extension module name — the OPM module that deploys the Gateway resource should simply be called `gateway`          | User directive                                                                             |
| Two-module pattern for cert-manager                                     | Separate operator deployment (`cert_manager`) from custom resource configuration (`cert_manager_config`); follows infrastructure/config separation principle             | User directive                                                                             |
| cert-manager operator based on Helm chart v1.20.0                      | Latest stable release; 4 sub-components (controller, webhook, cainjector, startupapicheck); images from `quay.io/jetstack/`                                             | `https://github.com/cert-manager/cert-manager/tree/v1.20.0/deploy/charts/cert-manager`      |
| No MetalLB integration in Gateway module                                | Gateway relies on MetalLB auto-assignment from existing L2 pool; no explicit IP pinning needed; MetalLB is a cluster prerequisite, not a module concern                 | User directive                                                                             |

---

## Phase 1: Gateway API Extension Module [PENDING]

Set up `catalog/v1alpha2/gateway_api/` as a standalone CUE module with CRD-imported type definitions.

- [x] **1.1 Create `gateway_api/` directory structure**
  - `gateway_api/cue.mod/module.cue` — new CUE module (`opmodel.dev/gateway-api@v1`)
  - `gateway_api/crds/` — raw downloaded CRD YAML files (not imported into CUE, kept for reference)
  - `gateway_api/version.yml` — tracks Gateway API version and download date
  - `gateway_api/PLAN.md` — detailed research and implementation reference (see `gateway_api/PLAN.md`)

- [x] 1.2 Download Gateway API CRDs (experimental channel)
  - URL: `https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/experimental-install.yaml`
  - Save to `gateway_api/crds/experimental-install.yaml`
  - Create `gateway_api/version.yml` — see `gateway_api/PLAN.md` for exact format

- [x] 1.3 Import CRDs using `timoni mod vendor crd`
  - Run `timoni mod vendor crd` against the downloaded experimental CRD YAML
  - Output organized into `gateway_api/v1/` (GA) and `gateway_api/v1alpha2/` (experimental)

- [x] 1.4 Validate Gateway API module
  - `cd catalog/v1alpha2/gateway_api && cue vet ./...`

## Phase 2: cert-manager Extension Module [PENDING]

Set up `catalog/v1alpha2/cert_manager/` using the official CUE registry module.

- [x] 2.1 Create `cert_manager/` module structure
  - `cert_manager/cue.mod/module.cue` — new CUE module (`opmodel.dev/cert-manager@v1`)
  - Add dependency: `cue.dev/x/crd/cert-manager.io@v0`
  - `cert_manager/version.yml` — tracks cert-manager version and CUE module version
  - `cert_manager/PLAN.md` — detailed research and implementation reference (see `cert_manager/PLAN.md`)

- [x] 2.2 Create type re-exports from registry module
  - `cert_manager/v1/types.cue` — re-export from `cue.dev/x/crd/cert-manager.io/v1`:
    - `#Certificate`, `#CertificateSpec`, `#CertificateStatus`
    - `#Issuer`, `#IssuerSpec`, `#IssuerStatus`
    - `#ClusterIssuer`, `#ClusterIssuerSpec`, `#ClusterIssuerStatus`
    - `#CertificateRequest` (auto-created by cert-manager, type available for reference)
  - Follow the re-export pattern from `opm/schemas/kubernetes/networking/v1/types.cue`

- [x] 2.3 Validate cert-manager module
  - `cd catalog/v1alpha2/cert_manager && cue vet ./...`

## Phase 3: OPM Schemas [COMPLETE]

Add platform-agnostic OPM schemas to `opm/schemas/` that abstract Gateway API and cert-manager concepts.

- [x] 3.1 Add Gateway schemas to `opm/schemas/network.cue`
  - `#GatewaySchema`: `gatewayClassName!`, `listeners!: [...]`, `addresses?`, `infrastructure?`
  - `#GatewayListenerSchema`: `name!`, `hostname?`, `port!`, `protocol!`, `tls?`, `allowedRoutes?`
  - `#GatewayAddressSchema`: `type?`, `value!`
  - cert-manager annotation field: `issuerRef?: { name!, kind?, group? }`

- [x] 3.2 Add `#TlsRouteSchema` to `opm/schemas/network.cue`
  - Embed `#RouteAttachmentSchema`
  - Fields: `hostnames?: [...string]`, `rules: [#TlsRouteRuleSchema, ...]`

- [x] 3.3 Add `#ReferenceGrantSchema` to `opm/schemas/network.cue`
  - Fields: `from!: [...]` (group, kind, namespace), `to!: [...]` (group, kind, name?)

- [x] 3.4 Add cert-manager schemas to `opm/schemas/security.cue`
  - `#CertificateSchema`: `secretName!`, `issuerRef!`, `dnsNames?`, `duration?`, `renewBefore?`, `privateKey?`
  - `#IssuerSchema`: `acme?`, `ca?`, `selfSigned?`, `vault?`
  - `#ClusterIssuerSchema`: same shape as `#IssuerSchema` (cluster-scoped variant)

- [x] 3.5 Remove `ingressClassName?` from `#RouteAttachmentSchema`
  - `ingressClassName` is a legacy Ingress field; Gateway API uses `gatewayRef` exclusively

- [x] 3.6 Add `#GatewayClassSchema` to `opm/schemas/network.cue`
  - Fields: `controllerName!`, `description?`, `parametersRef?`

- [x] 3.7 Add `#BackendTrafficPolicySchema` to `opm/schemas/network.cue`
  - Fields: `targetRef!: { group!, kind!, name! }`, `sessionPersistence?`, `retry?`

## Phase 4: OPM Resources [COMPLETE]

Create new resource definitions following the triple pattern (`#XxxResource` + `#Xxx` mixin + `#XxxDefaults`).

- [x] 4.1 `opm/resources/network/gateway.cue` — `#GatewayResource`, `#Gateway`, `#GatewayDefaults`
  - modulePath: `opmodel.dev/resources/network`, name: `gateway`
  - Default `gatewayClassName: "istio"`

- [x] 4.2 `opm/resources/network/reference_grant.cue` — `#ReferenceGrantResource`, `#ReferenceGrant`, `#ReferenceGrantDefaults`

- [x] 4.3 `opm/resources/security/certificate.cue` — `#CertificateResource`, `#Certificate`, `#CertificateDefaults`

- [x] 4.4 `opm/resources/security/issuer.cue` — `#IssuerResource`, `#Issuer`, `#IssuerDefaults`

- [x] 4.5 `opm/resources/security/cluster_issuer.cue` — `#ClusterIssuerResource`, `#ClusterIssuer`, `#ClusterIssuerDefaults`

- [x] 4.6 `opm/resources/network/gateway_class.cue` — `#GatewayClassResource`, `#GatewayClass`, `#GatewayClassDefaults`
  - For deploying custom GatewayClass instances; not needed for Istio-managed classes

- [x] 4.7 `opm/resources/network/backend_traffic_policy.cue` — `#BackendTrafficPolicyResource`, `#BackendTrafficPolicy`, `#BackendTrafficPolicyDefaults`

## Phase 5: OPM Traits [COMPLETE]

- [x] 5.1 `opm/traits/network/tls_route.cue` — `#TlsRouteTrait`, `#TlsRoute`, `#TlsRouteDefaults`
  - `appliesTo: [workload_resources.#ContainerResource]`
  - `spec: close({tlsRoute: schemas.#TlsRouteSchema})`

## Phase 6: Transformers — Gateway API [COMPLETE]

Create transformers that emit native Gateway API manifests. Import output types from `gateway_api/`.

- [x] 6.1 `gateway_transformer.cue` — `#GatewayTransformer`
  - requiredResources: `#GatewayResource` FQN
  - output: `gateway.networking.k8s.io/v1 Gateway`
  - Map `issuerRef` to `cert-manager.io/cluster-issuer` or `cert-manager.io/issuer` annotation

- [x] 6.2 `http_route_transformer.cue` — `#HttpRouteTransformer`
  - requiredTraits: `#HttpRouteTrait` FQN
  - output: `gateway.networking.k8s.io/v1 HTTPRoute`
  - Map `gatewayRef` to `spec.parentRefs`; derive service name from context

- [x] 6.3 `grpc_route_transformer.cue` — `#GrpcRouteTransformer`
  - requiredTraits: `#GrpcRouteTrait` FQN
  - output: `gateway.networking.k8s.io/v1 GRPCRoute`

- [x] 6.4 `tcp_route_transformer.cue` — `#TcpRouteTransformer`
  - requiredTraits: `#TcpRouteTrait` FQN
  - output: `gateway.networking.k8s.io/v1alpha2 TCPRoute`

- [x] 6.5 `tls_route_transformer.cue` — `#TlsRouteTransformer`
  - requiredTraits: `#TlsRouteTrait` FQN
  - output: `gateway.networking.k8s.io/v1 TLSRoute`

- [x] 6.6 `reference_grant_transformer.cue` — `#ReferenceGrantTransformer`
  - requiredResources: `#ReferenceGrantResource` FQN
  - output: `gateway.networking.k8s.io/v1 ReferenceGrant`

- [x] 6.7 `gateway_class_transformer.cue` — `#GatewayClassTransformer`
  - requiredResources: `#GatewayClassResource` FQN
  - output: `gateway.networking.k8s.io/v1 GatewayClass`
  - Import output type from `gateway_api/v1/types.cue`: `output: gwapiV1.#GatewayClass & { ... }`

- [x] 6.8 `backend_traffic_policy_transformer.cue` — `#BackendTrafficPolicyTransformer`
  - requiredResources: `#BackendTrafficPolicyResource` FQN
  - output: `gateway.networking.k8s.io/v1alpha2 BackendTrafficPolicy`
  - Import output type from `gateway_api/v1alpha2/types.cue`: `output: gwapiV1alpha2.#BackendTrafficPolicy & { ... }`

## Phase 7: Transformers — cert-manager [COMPLETE]

Create transformers that emit cert-manager manifests. Import output types from `cert_manager/`.

- [x] 7.1 `certificate_transformer.cue` — `#CertificateTransformer`
  - requiredResources: `#CertificateResource` FQN
  - output: `cert-manager.io/v1 Certificate`

- [x] 7.2 `issuer_transformer.cue` — `#IssuerTransformer`
  - requiredResources: `#IssuerResource` FQN
  - output: `cert-manager.io/v1 Issuer`

- [x] 7.3 `cluster_issuer_transformer.cue` — `#ClusterIssuerTransformer`
  - requiredResources: `#ClusterIssuerResource` FQN
  - output: `cert-manager.io/v1 ClusterIssuer`

## Phase 8: CRD Vendoring & Provider Implementation [COMPLETE]

### Ingress Removal

- [x] 8.1 Remove `#IngressTransformer` entry from `opm/providers/kubernetes/provider.cue` `#transformers` map
- [x] 8.2 Delete `opm/providers/kubernetes/transformers/ingress_transformer.cue`
- [x] 8.3 Remove `ingressClassName?: string` field from `#RouteAttachmentSchema` in `opm/schemas/network.cue:107`

### Gateway API CRD Vendoring

- [x] 8.4 Run `timoni mod vendor crd` (from within `opm/` module directory) — `timoni mod vendor crd -f /tmp/gateway-api-experimental.yaml` vendored 19 packages into `opm/cue.mod/gen/gateway.networking.k8s.io/` and `opm/cue.mod/gen/gateway.networking.x-k8s.io/`
- [x] 8.5 Verify timoni output in `opm/cue.mod/gen/gateway.networking.k8s.io/` — no file copying needed; `cue.mod/gen/` is the standard CUE vendor directory, importable directly as `gateway.networking.k8s.io/<resource>/<version>`
- [x] 8.6 Delete the three hand-written type files: `schemas/kubernetes/gateway/v1/types.cue`, `schemas/kubernetes/gateway/v1alpha2/types.cue`, `schemas/kubernetes/gateway/v1beta1/types.cue`
- [x] 8.7 Run `task vet:v1alpha2` — all three modules (opm, gateway_api, cert_manager) pass validation after Gateway API vendoring

### cert-manager Module Integration

- [x] **8.8 Add `"cue.dev/x/crd/cert-manager.io@v0"` to `opm/cue.mod/module.cue` deps (use `task update-deps` to pin exact version)**
- [x] 8.9 Replace `opm/schemas/kubernetes/certmanager/v1/types.cue` hand-written definitions with re-exports from `cue.dev/x/crd/cert-manager.io@v0` (thin alias file pattern, same as `schemas/kubernetes/` re-exports)
- [x] 8.10 Run `task vet:v1alpha2` — confirm cert-manager integration is valid

### Gateway API Transformers

- [x] 8.11 Write `opm/providers/kubernetes/transformers/http_route_transformer.cue` — maps `#HttpRouteTrait` spec → vendored HTTPRoute K8s resource (apiVersion: `gateway.networking.k8s.io/v1`)
- [x] 8.12 Write `opm/providers/kubernetes/transformers/grpc_route_transformer.cue` — maps `#GrpcRouteTrait` → GRPCRoute
- [x] 8.13 Write `opm/providers/kubernetes/transformers/tcp_route_transformer.cue` — maps `#TcpRouteTrait` → TCPRoute (apiVersion: `gateway.networking.k8s.io/v1alpha2`)
- [x] 8.14 Write `opm/providers/kubernetes/transformers/tls_route_transformer.cue` — maps `#TlsRouteTrait` → TLSRoute
- [x] 8.15 Write `opm/providers/kubernetes/transformers/gateway_transformer.cue` — maps `#GatewayResource` spec → Gateway (apiVersion: `gateway.networking.k8s.io/v1`)
- [x] 8.16 Write `opm/providers/kubernetes/transformers/gateway_class_transformer.cue` — maps `#GatewayClassResource` → GatewayClass
- [x] 8.17 Write `opm/providers/kubernetes/transformers/reference_grant_transformer.cue` — maps `#ReferenceGrantResource` → ReferenceGrant (apiVersion: `gateway.networking.k8s.io/v1beta1`)
- [x] 8.18 Write `opm/providers/kubernetes/transformers/backend_traffic_policy_transformer.cue` — maps `#BackendTrafficPolicyResource` → BackendTrafficPolicy (apiVersion: `gateway.networking.k8s.io/v1alpha2`)

### cert-manager Transformers

- [x] 8.19 Write `opm/providers/kubernetes/transformers/certificate_transformer.cue` — maps `#CertificateResource` → cert-manager `Certificate` (apiVersion: `cert-manager.io/v1`)
- [x] 8.20 Write `opm/providers/kubernetes/transformers/issuer_transformer.cue` — maps `#IssuerResource` → cert-manager `Issuer`
- [x] 8.21 Write `opm/providers/kubernetes/transformers/cluster_issuer_transformer.cue` — maps `#ClusterIssuerResource` → cert-manager `ClusterIssuer`

### Provider Registration

- [x] 8.22 Register all 11 new transformers in `opm/providers/kubernetes/provider.cue` `#transformers` map (keyed by `metadata.fqn`)

### Tests

- [x] 8.23 Write `http_route_transformer_tests.cue` — test HTTP host/path routing, parentRefs wiring
- [x] 8.24 Write `grpc_route_transformer_tests.cue` — test gRPC service/method routing
- [x] 8.25 Write `tcp_route_transformer_tests.cue` — test TCP backend refs
- [x] 8.26 Write `tls_route_transformer_tests.cue` — test TLS passthrough routing
- [x] 8.27 Write `gateway_transformer_tests.cue` — test listener configuration, gatewayClassName
- [x] 8.28 Write `gateway_class_transformer_tests.cue` — test controllerName field
- [x] 8.29 Write `reference_grant_transformer_tests.cue` — test from/to namespace wiring
- [x] 8.30 Write `backend_traffic_policy_transformer_tests.cue` — test sessionPersistence and retry config
- [x] 8.31 Write `certificate_transformer_tests.cue` — test dnsNames, issuerRef, secretName
- [x] 8.32 Write `issuer_transformer_tests.cue` — test ACME and CA solver output
- [x] 8.33 Write `cluster_issuer_transformer_tests.cue` — test ClusterIssuer spec output
- [x] 8.34 Run `task test:v1alpha2` — all tests pass
- [x] 8.35 Run `task test:v1alpha2:strict` — concreteness check passes
- [x] 8.36 Run `task check` — full suite passes

## Phase 9: Validation & Documentation [COMPLETE]

- [x] 9.1 Run full validation across all three modules
  - `cd catalog/v1alpha2/opm && cue vet ./...`
  - `cd catalog/v1alpha2/gateway_api && cue vet ./...`
  - `cd catalog/v1alpha2/cert_manager && cue vet ./...`
  - `cd catalog/v1alpha2/opm && cue vet -c -t test ./...` (run all `*_tests.cue` files)
- [x] 9.2 Update `catalog/v1alpha2/INDEX.md`
  - Add `gateway_api/` and `cert_manager/` sections to the project structure tree
  - Add definition tables for all new resources, traits, and transformers
- [x] 9.3 Update `modules/gateway_api/PLAN.md`
  - Mark Phase 2 (catalog prerequisite) as complete
  - Unblock Phases 3–5 for module implementation

- [x] 9.4 Validation checkpoint summary
  - All 11 Gateway API transformers have corresponding `*_tests.cue` files
  - All 3 cert-manager transformers have corresponding `*_tests.cue` files
  - `cue vet -c -t test ./...` passes with zero errors in `opm/`
  - `cue vet ./...` passes with zero errors in `gateway_api/` and `cert_manager/`
  - `catalog/Taskfile.yml` has `vet:v1alpha2` and `test:v1alpha2` task targets

## Phase 10: Gateway Module Implementation [IN PROGRESS]

Unblocked after Phase 9. Implements `modules/gateway/` (renamed from `gateway_api`) per its existing PLAN.md.

- [ ] **10.1 Rename `modules/gateway_api/` to `modules/gateway/`** ← CURRENT
  - Rename directory
  - Update `cue.mod/module.cue`: module path `opmodel.dev/modules/gateway@v0`, language `v0.16.0`
  - Update `module.cue`: fix `certificateRefs` → `certificateRef` (singular), add `"UDP"` to protocol enum, fix TLS mode default `*"Terminate" | "Passthrough"` (remove required marker)
  - Update `components.cue`: verify import paths after dep pinning
  - Update `PLAN.md`: reflect rename throughout
- [ ] 10.2 Define `#config` schema: gateway listeners, TLS configuration
- [ ] 10.3 Write `README.md` and `DEPLOYMENT_NOTES.md`
- [ ] 10.4 Create release config: `releases/gon1_nas2/gateway/`
- [ ] 10.5 Run `task update-deps` from workspace root to pin dependency versions
- [ ] 10.6 Validate: `cue vet -c ./modules/gateway/...`

## Phase 11: cert-manager Operator Module [PENDING]

Create `modules/cert_manager/` — an OPM module that deploys the cert-manager controller application (controller, webhook, cainjector, CRDs) based on the Helm chart v1.20.0.

- [ ] 11.1 Scaffold `modules/cert_manager/` directory
  - `cue.mod/module.cue`: module path `opmodel.dev/modules/cert_manager@v0`, language `v0.16.0`, dep `opmodel.dev@v1`
  - `module.cue`: metadata (name `"cert-manager"`, defaultNamespace `"cert-manager"`), `#config` schema
- [ ] 11.2 Define `#config` schema based on Helm chart v1.20.0 → `https://github.com/cert-manager/cert-manager/tree/v1.20.0/deploy/charts/cert-manager`
  - Controller: image tag, replicas, resources, log level
  - Webhook: image tag, replicas, resources
  - CA Injector: image tag, replicas, resources
  - CRDs: install toggle (`*true | false`)
  - Global: namespace, image pull policy, image registry override (`quay.io/jetstack/`)
- [ ] 11.3 Write `components.cue` — 4 sub-components (controller, webhook, cainjector, startupapicheck)
- [ ] 11.4 Write `debugValues` exercising the full `#config` surface → `modules/metallb/module.cue`
- [ ] 11.5 Write `README.md` and `DEPLOYMENT_NOTES.md` → `modules/metallb/README.md`
- [ ] 11.6 Create release config: `releases/gon1_nas2/cert_manager/release.cue` + `values.cue` → `releases/gon1_nas2/metallb/`
- [ ] 11.7 Run `task update-deps` from workspace root
- [ ] 11.8 Validate: `cue vet -c ./modules/cert_manager/...`

## Phase 12: cert-manager Custom Resources Module [PENDING]

Create `modules/cert_manager_config/` — a curated OPM module for deploying cert-manager custom resources (ClusterIssuer, Certificate, etc.) using the OPM resource types from `catalog/v1alpha2/opm/`.

- [ ] 12.1 Scaffold `modules/cert_manager_config/` directory
  - `cue.mod/module.cue`: module path `opmodel.dev/modules/cert_manager_config@v0`, language `v0.16.0`, dep `opmodel.dev@v1`
  - `module.cue`: metadata (name `"cert-manager-config"`, defaultNamespace `"cert-manager"`), `#config` schema
- [ ] 12.2 Define `#config` schema
  - `clusterIssuers`: map of named ClusterIssuer configs (ACME, CA, selfSigned)
  - `certificates`: map of named Certificate configs (secretName, dnsNames, issuerRef)
  - `issuers?`: optional map of namespace-scoped Issuer configs
- [ ] 12.3 Write `components.cue` — components using `resources_security.#ClusterIssuer`, `resources_security.#Certificate`, `resources_security.#Issuer`
- [ ] 12.4 Write `debugValues` exercising the full `#config` surface
- [ ] 12.5 Write `README.md` and `DEPLOYMENT_NOTES.md`
- [ ] 12.6 Create release config: `releases/gon1_nas2/cert_manager_config/release.cue` + `values.cue`
- [ ] 12.7 Run `task update-deps` from workspace root
- [ ] 12.8 Validate: `cue vet -c ./modules/cert_manager_config/...`

---

## Notes

- 2026-03-22: v1alpha2 directory layout: `opm/` (core OPM definitions), `gateway_api/` (Gateway API CUE types), `cert_manager/` (cert-manager CUE types), `kubernetes/` (deferred)
- 2026-03-22: `timoni mod vendor crd` won decisively against `cue import` — produces named sub-types, proper constraints, pinned apiVersion/kind; experiment results at `local/experiments/crd-import-test/RESULTS.md`
- 2026-03-22: Option B chosen — adopt timoni-generated type names directly; no re-export/mapping layer. Impact is zero since no transformers referencing Gateway API K8s types existed yet (confirmed by grep of `opm/providers/kubernetes/transformers/`)
- 2026-03-22: cert-manager has official CUE bindings at `cue.dev/x/crd/cert-manager.io` — no manual import needed → `https://cue.dev/docs/curated-module-crd-cert-manager/`
- 2026-03-22: Existing `#RouteAttachmentSchema` already contains `gatewayRef` and `tls` fields — existing route traits need new transformers but no schema changes → `opm/schemas/network.cue:93–107`
- 2026-03-22: Gateway API experimental CRDs exceed the annotation size limit for `kubectl apply` — installation requires `kubectl apply --server-side` → `https://gateway-api.sigs.k8s.io/guides/getting-started/`
- 2026-03-22: Phases 1 and 2 are fully independent and can run in parallel
- 2026-03-22: GatewayClass and BackendTrafficPolicy added as full OPM resources (Option A confirmed): type definitions in `gateway_api/` extension module + schemas/resources/transformers in `opm/` module → user directive
- 2026-03-22: Total new transformer count is 11 (6 Gateway API route/infra + 2 Gateway API class/policy + 3 cert-manager)
- 2026-03-22: `security.cue` has `ingressClassName` on lines 113 and 212 — these are for cert-manager ACME HTTP01 solver, NOT Ingress controller references; do NOT remove them
- 2026-03-22: `security.cue` contains duplicate schema definitions (lines 77–174 and 176–273) — noted for cleanup in Phase 9 or 10
- 2026-03-23: timoni-generated type names confirmed (task 8.4). Each `types_gen.cue` exposes a top-level resource type and its spec: `#HTTPRoute`/`#HTTPRouteSpec` (httproute/v1, v1beta1), `#GRPCRoute`/`#GRPCRouteSpec` (grpcroute/v1), `#Gateway`/`#GatewaySpec` (gateway/v1, v1beta1), `#GatewayClass`/`#GatewayClassSpec` (gatewayclass/v1, v1beta1), `#ReferenceGrant`/`#ReferenceGrantSpec` (referencegrant/v1, v1beta1), `#TCPRoute`/`#TCPRouteSpec` (tcproute/v1alpha2), `#TLSRoute`/`#TLSRouteSpec` (tlsroute/v1, v1alpha2, v1alpha3), `#UDPRoute`/`#UDPRouteSpec` (udproute/v1alpha2), `#ListenerSet`/`#ListenerSetSpec` (listenerset/v1), `#BackendTLSPolicy`/`#BackendTLSPolicySpec` (backendtlspolicy/v1, v1alpha3), `#XBackendTrafficPolicy`/`#XBackendTrafficPolicySpec` (x-k8s.io/xbackendtrafficpolicy/v1alpha1), `#XMesh`/`#XMeshSpec` (x-k8s.io/xmesh/v1alpha1). Note: `BackendTrafficPolicy` is vendored as `#XBackendTrafficPolicy` under `gateway.networking.x-k8s.io/xbackendtrafficpolicy/v1alpha1`, NOT `gateway.networking.k8s.io/v1alpha2` — transformer in 8.18 must use the x-k8s.io import path.
- 2026-03-23: Module `modules/gateway_api/` renamed to `modules/gateway/` — shorter name, avoids confusion with catalog extension module `catalog/v1alpha2/gateway_api/`; the catalog extension retains its name
- 2026-03-23: `modules/gateway_api/module.cue` has schema mismatches vs catalog: `certificateRefs` (plural) should be singular `certificateRef` to match `#ListenerSchema`, missing `"UDP"` protocol value, TLS `mode!` is required but should default `*"Terminate" | "Passthrough"` — fix during Phase 10 rename
- 2026-03-23: `modules/gateway_api/cue.mod/module.cue` has language `v0.15.0` (should be `v0.16.0`) and unpinned deps `v0.0.0` — fix during Phase 10 rename, then run `task update-deps`
- 2026-03-23: cert-manager uses two-module pattern: `modules/cert_manager/` (operator — deploys controller application via Helm chart v1.20.0) and `modules/cert_manager_config/` (custom resources — ClusterIssuers, Certificates, Issuers)
- 2026-03-23: Phase 10 MetalLB integration reference removed — Gateway module does not need explicit MetalLB configuration; MetalLB auto-assigns from existing pool and is treated as a cluster prerequisite
- 2026-03-23: Module `modules/gateway_api/` renamed to `modules/gateway/` — shorter name, avoids confusion with catalog extension module `catalog/v1alpha2/gateway_api/`; the catalog extension retains its name
- 2026-03-23: `modules/gateway_api/module.cue` has schema mismatches vs catalog: `certificateRefs` (plural) should be singular `certificateRef` to match `#ListenerSchema`, missing `"UDP"` protocol value, TLS `mode!` is required but should default `*"Terminate" | "Passthrough"` — fix during Phase 10 rename
- 2026-03-23: `modules/gateway_api/cue.mod/module.cue` has language `v0.15.0` (should be `v0.16.0`) and unpinned deps `v0.0.0` — fix during Phase 10 rename, then run `task update-deps`
- 2026-03-23: cert-manager uses two-module pattern: `modules/cert_manager/` (operator — deploys controller application via Helm chart v1.20.0) and `modules/cert_manager_config/` (custom resources — ClusterIssuers, Certificates, Issuers)
- 2026-03-23: Phase 10 MetalLB integration reference removed — Gateway module does not need explicit MetalLB configuration; MetalLB auto-assigns from existing pool and is treated as a cluster prerequisite
