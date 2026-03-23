---
status: not-started
phase: 2
updated: 2026-03-22
---

# cert-manager Extension Module

## Goal

Create a standalone CUE module under `catalog/v1alpha2/cert_manager/` that provides type-safe CUE definitions for all cert-manager v1 resources by consuming the official CUE registry module at `cue.dev/x/crd/cert-manager.io`. Re-export the upstream types with any OPM-specific constraints layered on top.

---

## Research Reference

This document captures all research gathered before implementation. Refer to it when making implementation decisions.

---

## Resource Inventory

### cert-manager API group: `cert-manager.io/v1`

All resources below are stable and part of the cert-manager v1 API. They are cluster-installed as CRDs on the `admin@gon1-nas2` cluster.

| Resource | Scope | Description |
|---|---|---|
| `Certificate` | Namespaced | Declares a desired X.509 certificate; cert-manager fulfills it by creating a Kubernetes Secret |
| `CertificateRequest` | Namespaced | Intermediate resource; auto-created by cert-manager when processing a Certificate — not managed directly |
| `Issuer` | Namespaced | Configures a certificate-signing backend scoped to one namespace |
| `ClusterIssuer` | Cluster | Same as Issuer but available across all namespaces |
| `Order` | Namespaced | ACME order resource; auto-created during ACME challenge flows — not managed directly |
| `Challenge` | Namespaced | ACME challenge resource; auto-created by cert-manager — not managed directly |

### Resources included in this OPM module

| Resource | Reason |
|---|---|
| `Certificate` | Explicitly declared by OPM modules that need a named TLS Secret |
| `Issuer` | Namespaced issuer; first-class OPM resource per user directive |
| `ClusterIssuer` | Cluster-scoped issuer; first-class OPM resource per user directive |

### Resources not included

| Resource | Reason |
|---|---|
| `CertificateRequest` | Auto-created by cert-manager when a Certificate is processed; no direct management needed |
| `Order` | Auto-created during ACME flows; not user-facing |
| `Challenge` | Auto-created during ACME flows; not user-facing |

---

## CUE Registry Module

Unlike Gateway API, cert-manager has an official CUE module published to the CUE registry. No manual CRD download or `cue import` is required.

| Property | Value |
|---|---|
| Module path | `cue.dev/x/crd/cert-manager.io` |
| Registry | `registry.cue.works` |
| Documentation | `https://cue.dev/docs/curated-module-crd-cert-manager/` |
| Latest version | `v0` (follow `cue.dev/x/crd/cert-manager.io@v0`) |
| cert-manager version tracked | v1.17.x |

### Why use the registry module instead of `cue import`

The CUE registry module is generated from the authoritative OpenAPI schema published by the cert-manager project. Compared to running `cue import` locally:

- Types include CUE constraints derived from schema validation rules
- The module is versioned independently and updated by the cert-manager project maintainers
- No local CRD download or import step is needed — `cue mod tidy` resolves the dependency
- Upstream type quality is higher than bare `cue import` output

The only reason to fall back to `cue import` would be if the registry module fell significantly behind the installed cert-manager version. At cert-manager v1.17.x, the registry module is current.

### What the registry module provides

The module exports one package per API version. The relevant package is `cue.dev/x/crd/cert-manager.io/v1`, which contains:

- `#Certificate` — full Certificate spec including all optional fields
- `#CertificateSpec` — the `.spec` sub-type
- `#CertificateStatus` — the `.status` sub-type
- `#CertificateRequest` — available for reference even though not directly managed
- `#Issuer` — full Issuer spec
- `#IssuerSpec` — the `.spec` sub-type containing all solver configurations
- `#IssuerStatus`
- `#ClusterIssuer` — full ClusterIssuer spec (same spec shape as Issuer)
- `#ClusterIssuerSpec`
- `#ClusterIssuerStatus`

---

## Key Resource Shapes

### Certificate

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-com-tls
  namespace: app-namespace
spec:
  secretName: example-com-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - example.com
    - www.example.com
  duration: 2160h    # 90 days
  renewBefore: 360h  # 15 days
  privateKey:
    algorithm: RSA
    size: 2048
```

Key fields for OPM schema mapping:

| Certificate field | OPM schema field | Notes |
|---|---|---|
| `spec.secretName` | `#CertificateSchema.secretName` | Name of the Secret cert-manager creates |
| `spec.issuerRef.name` | `#CertificateSchema.issuerRef.name` | Name of the Issuer or ClusterIssuer |
| `spec.issuerRef.kind` | `#CertificateSchema.issuerRef.kind` | `"Issuer"` or `"ClusterIssuer"` |
| `spec.issuerRef.group` | `#CertificateSchema.issuerRef.group` | Optional; defaults to `cert-manager.io` |
| `spec.dnsNames` | `#CertificateSchema.dnsNames` | List of SANs; typically derived from hostnames |
| `spec.duration` | `#CertificateSchema.duration` | Optional; default 90 days |
| `spec.renewBefore` | `#CertificateSchema.renewBefore` | Optional; default 15 days |
| `spec.privateKey` | `#CertificateSchema.privateKey` | Optional; algorithm and key size |

### Issuer (ACME / Let's Encrypt)

The most common issuer type for internet-facing services is ACME with Let's Encrypt. Two solver strategies are available: HTTP-01 (uses a temporary HTTP endpoint on the domain) and DNS-01 (uses a DNS TXT record).

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-account-key
    solvers:
      - http01:
          gatewayHTTPRoute:
            parentRefs:
              - name: istio-ingress
                namespace: istio-ingress
                kind: Gateway
```

The `http01.gatewayHTTPRoute` solver (available since cert-manager v1.15) creates a temporary `HTTPRoute` to answer ACME HTTP-01 challenges. It requires a Gateway that accepts HTTP traffic and allows routes from the cert-manager namespace.

```yaml
# Alternative: DNS-01 solver using a cloud DNS provider
spec:
  acme:
    solvers:
      - dns01:
          cloudDNS:
            project: my-gcp-project
            serviceAccountSecretRef:
              name: clouddns-dns01-solver
              key: key.json
```

Key fields for OPM schema mapping:

| Issuer field | OPM schema field | Notes |
|---|---|---|
| `spec.acme.server` | `#IssuerSchema.acme.server` | Use staging URL for testing |
| `spec.acme.email` | `#IssuerSchema.acme.email` | Registration email for the ACME account |
| `spec.acme.privateKeySecretRef.name` | `#IssuerSchema.acme.privateKeySecretRef` | Auto-created by cert-manager on first use |
| `spec.acme.solvers` | `#IssuerSchema.acme.solvers` | Array of solver configurations |
| `spec.ca` | `#IssuerSchema.ca` | For internal CA issuers |
| `spec.selfSigned` | `#IssuerSchema.selfSigned` | For self-signed certificates |
| `spec.vault` | `#IssuerSchema.vault` | For HashiCorp Vault integration |

### ClusterIssuer

`ClusterIssuer` has an identical spec to `Issuer`. The only difference is scope: an `Issuer` can only sign certificates in its own namespace, while a `ClusterIssuer` can sign certificates in any namespace.

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-staging-account-key
    solvers:
      - http01:
          gatewayHTTPRoute:
            parentRefs:
              - name: istio-ingress
                namespace: istio-ingress
                kind: Gateway
```

OPM field mapping for ClusterIssuer is identical to Issuer — the resource kind is the distinguishing factor, not the spec shape.

---

## Solver Strategy: HTTP-01 with Gateway API

The cluster runs Istio ambient mode with Gateway API. The recommended solver for this environment is `http01.gatewayHTTPRoute`, which creates a temporary HTTPRoute for each ACME challenge without requiring Ingress.

### How `http01.gatewayHTTPRoute` works

1. cert-manager receives a Certificate request
2. cert-manager creates a temporary `HTTPRoute` in the cert-manager namespace pointing at a challenge solver pod
3. The HTTPRoute is attached to the parent Gateway specified in the solver config
4. Let's Encrypt reaches `http://<domain>/.well-known/acme-challenge/<token>` via the Gateway
5. cert-manager validates the response, obtains the certificate, and deletes the temporary HTTPRoute

### Requirements for Gateway HTTP-01 solver

The parent Gateway must:

- Have an HTTP listener on port 80
- Allow routes from the cert-manager namespace (`allowedRoutes.namespaces.from: All` or a `ReferenceGrant`)

```yaml
# The istio-ingress Gateway must allow HTTP routes from the cert-manager namespace
# This is typically configured via a ReferenceGrant:
apiVersion: gateway.networking.k8s.io/v1
kind: ReferenceGrant
metadata:
  name: cert-manager-challenge
  namespace: istio-ingress
spec:
  from:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      namespace: cert-manager
  to:
    - group: gateway.networking.k8s.io
      kind: Gateway
```

The OPM `#ReferenceGrantResource` (from Phase 4.2 of the main plan) covers this.

---

## Gateway API Integration

cert-manager v1.15+ can automatically provision `Certificate` resources from a `Gateway` resource without requiring an explicit `Certificate` manifest.

### How Gateway annotation-based provisioning works

1. Add `cert-manager.io/cluster-issuer` (or `cert-manager.io/issuer`) annotation to the `Gateway`
2. cert-manager watches for annotated Gateway resources
3. For each TLS listener that meets all conditions (see below), cert-manager creates a `Certificate`
4. The Certificate's `dnsNames` are populated from `listener.hostname`
5. The resulting Secret is named after `listener.tls.certificateRefs[0].name`

When using this mechanism, no explicit `Certificate` OPM resource is needed — the `#GatewayTransformer` handles it by writing the annotation onto the Gateway manifest.

### Conditions required on a listener for auto-provisioning

All four conditions must be satisfied simultaneously:

| Condition | Required value |
|---|---|
| `listener.hostname` | Must be set (non-empty) |
| `listener.protocol` | Must be `HTTPS` |
| `listener.tls.mode` | Must be `Terminate` |
| `listener.tls.certificateRefs` | Must contain at least one entry naming a Secret |

### Annotations emitted by `#GatewayTransformer`

The transformer maps the OPM `issuerRef` field to the appropriate annotation:

| `issuerRef.kind` | Annotation emitted |
|---|---|
| `"ClusterIssuer"` (or unset) | `cert-manager.io/cluster-issuer: <name>` |
| `"Issuer"` | `cert-manager.io/issuer: <name>` |

Optional additional annotations (pass-through from OPM schema):

```yaml
cert-manager.io/duration: 2160h
cert-manager.io/renew-before: 360h
cert-manager.io/private-key-algorithm: RSA
cert-manager.io/private-key-size: "2048"
cert-manager.io/issuer-kind: AWSPCAIssuer        # for out-of-tree issuers
cert-manager.io/issuer-group: awspca.cert-manager.io
```

---

## ACME Staging vs Production

Let's Encrypt provides two environments. Always validate the full flow against staging before switching to production.

| Environment | ACME server URL | Rate limits | Certificate validity |
|---|---|---|---|
| Staging | `https://acme-staging-v02.api.letsencrypt.org/directory` | Very high | Not trusted by browsers |
| Production | `https://acme-v02.api.letsencrypt.org/directory` | Strict | Trusted by all browsers |

The OPM `#ClusterIssuerDefaults` should default to the staging URL. Operators explicitly override to production when ready.

---

## Module Structure

```text
cert_manager/
├── cue.mod/
│   ├── module.cue          # CUE module: opmodel.dev/cert-manager@v1
│   └── pkg/                # Auto-populated by cue mod tidy (registry cache)
├── v1/
│   └── types.cue           # Re-exports from cue.dev/x/crd/cert-manager.io/v1
├── version.yml             # Tracks cert-manager version and CUE module pin
├── PLAN.md                 # This document
└── README.md               # Brief module overview
```

The `cue.mod/pkg/` directory is managed by the CUE toolchain. Do not edit it manually.

---

## version.yml Format

```yaml
name: cert-manager
version: v1.17.0
cue_module: cue.dev/x/crd/cert-manager.io@v0
source: https://github.com/cert-manager/cert-manager/releases/tag/v1.17.0
updated: 2026-03-22
notes: >
  Using the official CUE registry module rather than a manual cue import.
  Run `cue mod tidy` inside cert_manager/ to resolve or update the dependency.
  Check https://cue.dev/docs/curated-module-crd-cert-manager/ for module updates.
```

---

## Re-export Pattern

The `v1/types.cue` file re-exports the upstream types from the registry module. It does not duplicate definitions — it makes the upstream types available under the `opmodel.dev/cert-manager@v1` module path so OPM transformers can import them without depending on the upstream module path directly.

This follows the same re-export pattern used in the v1alpha1 catalog. The upstream import path is aliased once at the top of the file; all definitions reference that alias.

The re-export file should cover:

- `#Certificate` with `apiVersion` constrained to `"cert-manager.io/v1"` and `kind` to `"Certificate"`
- `#Issuer` with `apiVersion` constrained to `"cert-manager.io/v1"` and `kind` to `"Issuer"`
- `#ClusterIssuer` with `apiVersion` constrained to `"cert-manager.io/v1"` and `kind` to `"ClusterIssuer"`

Sub-types (`#CertificateSpec`, `#IssuerSpec`, `#ClusterIssuerSpec`) are re-exported for use in the OPM schema definitions.

---

## Implementation Tasks

- [ ] **2.1 Create `cue.mod/module.cue`** ← CURRENT
  - Module path: `opmodel.dev/cert-manager@v1`
  - Language: `v0.15.0` (match `opm/cue.mod/module.cue`)
  - Add dependency: `cue.dev/x/crd/cert-manager.io@v0: v0.x.x` (pin after running `cue mod get`)

- [ ] 2.2 Resolve registry dependency
  - `cue mod get cue.dev/x/crd/cert-manager.io@v0`
  - `cue mod tidy`
  - Confirm `cue.mod/module.cue` contains the correct version pin
  - Record the pinned version in `version.yml`

- [ ] 2.3 Create `v1/types.cue`
  - Import `cue.dev/x/crd/cert-manager.io/v1`
  - Re-export `#Certificate`, `#Issuer`, `#ClusterIssuer` with constrained `apiVersion` and `kind`
  - Re-export `#CertificateSpec`, `#IssuerSpec`, `#ClusterIssuerSpec` for use in OPM schemas

- [ ] 2.4 Create `version.yml`
  - Record cert-manager version, CUE module path, and download/update date
  - Use format shown in the version.yml section above

- [ ] 2.5 Validate
  - `cue vet ./...` from this directory

---

## Links

- [cert-manager documentation](https://cert-manager.io/docs/)
- [cert-manager v1 API reference](https://cert-manager.io/docs/reference/api-docs/)
- [cert-manager Gateway API integration](https://cert-manager.io/docs/usage/gateway/)
- [cert-manager ACME HTTP-01 with Gateway API](https://cert-manager.io/docs/configuration/acme/http01/#configuring-the-http-01-gateway-api-solver)
- [cert-manager ACME DNS-01](https://cert-manager.io/docs/configuration/acme/dns01/)
- [Official CUE module: cue.dev/x/crd/cert-manager.io](https://cue.dev/docs/curated-module-crd-cert-manager/)
- [CUE module system: cue mod get](https://cuelang.org/docs/reference/cli/cue-mod-get/)
- [Let's Encrypt staging environment](https://letsencrypt.org/docs/staging-environment/)
- [Let's Encrypt rate limits](https://letsencrypt.org/docs/rate-limits/)
