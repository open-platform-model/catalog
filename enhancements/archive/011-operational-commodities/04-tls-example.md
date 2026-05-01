# TLS Certificates — Second Worked Example

This document walks TLS certificate issuance (cert-manager) through the same pattern as [03-backup-example.md](03-backup-example.md). It is a second data point for OQ-5 (does the pattern generalize?) and drives the optional per-component provenance annotation in [D11 / D13](08-decisions.md).

## A Note on Primitive Choice: `#Resource`, Not `#Trait`

A `#Trait` extends the functionality of an existing resource on a component (scaling, restart policy, security context). A TLS certificate doesn't extend anything about the workload — it's a standalone k8s entity (`cert-manager.io/v1.Certificate`) that happens to live alongside the component. It has its own lifecycle (renewal, reconciliation), its own status, and could in principle be authored without a consuming workload.

TLS certificates therefore fit `#Resource` — "what must exist?" — rather than `#Trait`. The component declares "I need a Certificate resource with these hostnames" the same way it declares "I need a Container resource with this image." See [D15](08-decisions.md) for the decision rationale.

## Layer Split

| Layer | Belongs to | Examples |
| --- | --- | --- |
| Component-local | `#CertificateResource` | hostnames the component needs covered, secret name hint, key usages, per-component key algorithm override |
| Module-level | `#CertificatePolicy` (Directive) | issuer reference, renewal window, default key algorithm, subject fields, private-key rotation |
| Platform-level | `#Platform.#ctx.platform.tls.issuers` | pre-configured `Issuer` / `ClusterIssuer` references (name + kind + namespace) |

Same three-layer shape as backup. Differs in which component-level primitive carries the local facts (Resource here vs. Trait in backup) and in output cardinality — see [Cardinality Finding](#cardinality-finding) below.

## File Layout

Co-located resource + directive, matching the convention established by backup:

```text
catalog/opm/v1alpha1/operations/tls/
├── resource.cue          — #CertificateResource + #Certificate (component wrapper) + #KeyAlgorithm
├── directive.cue         — #CertificatePolicy
├── resource_tests.cue
└── directive_tests.cue
```

Import path: `opmodel.dev/opm/v1alpha1/operations/tls@v1`.

## `#CertificateResource` — Component-Local Facts

```cue
// catalog/opm/v1alpha1/operations/tls/resource.cue
package tls

import (
    prim "opmodel.dev/core/v1alpha1/primitives@v1"
    component "opmodel.dev/core/v1alpha1/component@v1"
)

#CertificateResource: prim.#Resource & {
    metadata: {
        modulePath:  "opmodel.dev/opm/v1alpha1/operations/tls"
        version:     "v1"
        name:        "certificate"
        description: "A TLS certificate that should be issued for the component"
        labels: {
            "resource.opmodel.dev/category": "security"
        }
    }

    spec: close({
        certificate: {
            // DNS names the certificate must cover. At least one required.
            // Typically references #ctx.runtime.route.domain for the environment domain.
            hostnames!: [...string] & list.MinItems(1)

            // Secret name where cert-manager should place the resulting certificate + key.
            // Defaults to "{resourceName}-tls" — resolved via #ctx.runtime.components[x].resourceName.
            secretName?: string

            // Key usages. "server auth" is the common default.
            usages?: [...("server auth" | "client auth" | "code signing" | "email protection" |
                          "s/mime" | "ipsec end system" | "ipsec tunnel" | "ipsec user" |
                          "timestamping" | "ocsp signing" | "microsoft sgc" | "netscape sgc")]

            // Optional — override module-level key algorithm per-component (rare).
            // Absent → inherit from the policy.
            keyAlgorithm?: #KeyAlgorithm
        }
    })
}

// Component wrapper for ergonomic composition — matches the convention used
// by #CRDs and other existing resource wrappers in the catalog.
#Certificate: component.#Component & {
    #resources: {(#CertificateResource.metadata.fqn): #CertificateResource}
}

#KeyAlgorithm: close({
    type: "RSA" | "ECDSA" | "Ed25519"
    if type == "RSA" {
        size: 2048 | 3072 | 4096 | *2048
    }
    if type == "ECDSA" {
        size: 256 | 384 | 521 | *256
    }
})
```

Observations:

- Hostnames are typically computed from `#ctx.runtime.route.domain`. No duplicated authoring.
- `secretName` defaults to a function of `resourceName`; the component's own workload can reference the same default when mounting the cert as a TLS volume.
- Per-component key algorithm override exists for rare cases (e.g., an API service wanting ECDSA for TLS handshake performance while the rest of the module uses RSA).
- `#Certificate` is the ergonomic component-wrapper that authors import. The underlying `#CertificateResource` is the primitive a transformer matches against.

## `#CertificatePolicy` — Module-Level Orchestration

```cue
// catalog/opm/v1alpha1/operations/tls/directive.cue
package tls

import (
    prim "opmodel.dev/core/v1alpha1/primitives@v1"
)

#CertificatePolicy: prim.#Directive & {
    metadata: {
        modulePath:  "opmodel.dev/opm/v1alpha1/operations/tls"
        version:     "v1"
        name:        "certificate"
        description: "Issuer, renewal window, key algorithm for certificates covering a set of components"
        labels: {
            "directive.opmodel.dev/category": "security"
        }
    }

    #spec: certificate: {
        // Named reference to a platform-configured Issuer.
        // Resolved at render against #Platform.#ctx.platform.tls.issuers[issuer].
        issuer!: string

        // Renewal window — cert-manager-native duration strings.
        renewalWindow?: close({
            duration:    string | *"2160h"   // 90 days
            renewBefore: string | *"720h"    // 30 days before expiry
        })

        // Default key algorithm for certs produced by this policy.
        // Components may override individually via #CertificateResource.spec.certificate.keyAlgorithm.
        keyAlgorithm?: #KeyAlgorithm & {
            type: *"RSA" | _
            if type == "RSA"   { size: *2048 | _ }
            if type == "ECDSA" { size: *256  | _ }
        }

        // Optional subject fields applied uniformly to all certs in this policy.
        subject?: close({
            organizations?:       [...string]
            organizationalUnits?: [...string]
            countries?:           [...string]
            localities?:          [...string]
            provinces?:           [...string]
        })

        // Rotation policy — whether to regenerate the private key on renewal.
        privateKeyRotation?: *"Never" | "Always"
    }
}
```

No restore field. TLS has no counterpart; the directive is purely declarative configuration that the transformer renders.

## `#CertificateTransformer`

```cue
// catalog/cert_manager/v1alpha1/transformers/certificate.cue
package transformers

import (
    transformer "opmodel.dev/core/v1alpha1/transformer@v1"
    tls "opmodel.dev/opm/v1alpha1/operations/tls@v1"
)

#CertificateTransformer: transformer.#PolicyTransformer & {
    metadata: {
        modulePath:  "opmodel.dev/cert_manager/v1alpha1/transformers"
        version:     "v1"
        name:        "certificate-transformer"
        description: "Renders a #CertificatePolicy directive into cert-manager Certificate CRs, one per covered component"
    }

    requiredDirectives: [tls.#CertificatePolicy.metadata.fqn]
    requiredResources:  [tls.#CertificateResource.metadata.fqn]

    readsContext: ["tls.issuers"]   // see platform-context convention in 02-design.md

    producesKinds: ["cert-manager.io/v1.Certificate"]

    // Cardinality: N outputs per directive. Transformer iterates appliesTo
    // components, reads each component's #CertificateResource, emits one Certificate CR
    // tagged with opm.opmodel.dev/owner-component per D11 / D13 (08-decisions.md).
}
```

Note the match predicate: `requiredResources` (was `requiredTraits` before 011's D15 clarification). `#PolicyTransformer` already supports both; see [06-policy-transformer.md](06-policy-transformer.md).

Provider registration:

```cue
#Provider: provider.#Provider & {
    metadata: { name: "cert-manager", type: "kubernetes", version: "1.16.0" }
    #policyTransformers: {
        (transformers.#CertificateTransformer.metadata.fqn): transformers.#CertificateTransformer
    }
}
```

## Module Author Experience

```cue
package strix_media

import (
    m "opmodel.dev/core/v1alpha1/module@v1"
    policy "opmodel.dev/core/v1alpha1/policy@v1"
    tls "opmodel.dev/opm/v1alpha1/operations/tls@v1"
)

m.#Module

metadata: {
    modulePath: "opmodel.dev/modules"
    name:       "strix-media"
    version:    "0.1.0"
}

#components: {
    "web": #StatelessWorkload & tls.#Certificate & {
        spec: {
            container: { image: "strix-web:latest" }
            certificate: {
                hostnames: ["strix.\(#ctx.runtime.route.domain)"]
                usages:    ["server auth"]
            }
        }
    }

    "api": #StatelessWorkload & tls.#Certificate & {
        spec: {
            container: { image: "strix-api:latest" }
            certificate: {
                hostnames:    ["api.strix.\(#ctx.runtime.route.domain)"]
                usages:       ["server auth"]
                keyAlgorithm: { type: "ECDSA", size: 256 }   // override
            }
        }
    }

    "db": #StatefulWorkload & {
        spec: container: { image: "postgres:16" }
        // no certificate resource — db is internal only
    }
}

#policies: {
    "public-tls": policy.#Policy & {
        appliesTo: components: ["web", "api"]
        #directives: {
            (tls.#CertificatePolicy.metadata.fqn): tls.#CertificatePolicy & {
                #spec: certificate: {
                    issuer: "letsencrypt-prod"
                    renewalWindow: {
                        duration:    "2160h"    // 90d
                        renewBefore: "720h"     // 30d
                    }
                    keyAlgorithm: { type: "RSA", size: 2048 }
                    subject: organizations: ["Jacero AB"]
                }
            }
        }
    }
}
```

Authoring shape: `#StatelessWorkload & tls.#Certificate & { ... }` — the workload mixin + the certificate mixin, both component-wrappers, intersected. Spec fields from each mixin land in the component's `spec` via CUE unification.

### Platform Side (platform-team authored)

```cue
#Platform & {
    #ctx: platform: tls: issuers: {
        "letsencrypt-prod": {
            kind: "ClusterIssuer"
            name: "letsencrypt-prod"
        }
        "letsencrypt-staging": {
            kind: "ClusterIssuer"
            name: "letsencrypt-staging"
        }
        "internal-ca": {
            kind:      "Issuer"
            name:      "internal-ca"
            namespace: "cert-manager"
        }
    }
}
```

### Rendered Output

Two `Certificate` CRs, one per covered component, each tagged with `opm.opmodel.dev/owner-component`:

```yaml
# Certificate for web
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: strix-media-web-tls
  namespace: media
  annotations:
    opm.opmodel.dev/owner-policy:      public-tls
    opm.opmodel.dev/owner-directive:   opmodel.dev/opm/v1alpha1/operations/tls/certificate@v1
    opm.opmodel.dev/owner-transformer: opmodel.dev/cert_manager/v1alpha1/transformers/certificate-transformer@v1
    opm.opmodel.dev/owner-component:   web
spec:
  secretName: strix-media-web-tls
  dnsNames: [strix.dev.example.com]
  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt-prod
  duration:    2160h
  renewBefore: 720h
  privateKey: { algorithm: RSA, size: 2048 }
  subject: organizations: [Jacero AB]
  usages: [server auth]

---
# Certificate for api (ECDSA override lands here)
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: strix-media-api-tls
  namespace: media
  annotations:
    opm.opmodel.dev/owner-policy:      public-tls
    opm.opmodel.dev/owner-directive:   opmodel.dev/opm/v1alpha1/operations/tls/certificate@v1
    opm.opmodel.dev/owner-transformer: opmodel.dev/cert_manager/v1alpha1/transformers/certificate-transformer@v1
    opm.opmodel.dev/owner-component:   api
spec:
  secretName: strix-media-api-tls
  dnsNames: [api.strix.dev.example.com]
  issuerRef: { kind: ClusterIssuer, name: letsencrypt-prod }
  privateKey: { algorithm: ECDSA, size: 256 }
  usages: [server auth]
```

## Cardinality Finding

Backup's `#BackupScheduleTransformer` emits **one** `Schedule` CR per policy (module-scope, single output). TLS's `#CertificateTransformer` emits **N** `Certificate` CRs per policy — one per covered component.

Both cardinalities coexist inside the same `#PolicyTransformer` scope. The transformer iterates its inputs and emits whatever shape honestly reflects its output cardinality. The pipeline attaches provenance annotations; the optional `opm.opmodel.dev/owner-component` captures per-component attribution when applicable.

This is the shape that motivated the refinement in [D11](08-decisions.md) (optional fourth annotation) and [D13](08-decisions.md) (module-scope by default; per-component attribution via annotation). No further changes to `#PolicyTransformer`'s schema were needed to accommodate TLS.

## Version Pairing

Both `#CertificateResource` and `#CertificatePolicy` live in `opmodel.dev/opm/v1alpha1/operations/tls@v1`. The K8up-style safety net applies: the cert-manager transformer pins both FQNs in its match predicate, so a misaligned import fails at render time rather than producing inconsistent output.

No explicit `pairsWith` field. Same convention as backup. See [D8](08-decisions.md) and [OQ-2](09-open-questions.md).

## What TLS Does Not Address

- **Gateway listener TLS termination.** When the Gateway (via the Gateway API) terminates TLS for ingress traffic, the listener's certificate is the Gateway's concern, not the module's. Platform teams configure listeners to use cert-manager-produced Secrets — but that wiring happens at platform install time, outside any individual module. Modules that serve TLS behind an existing Gateway do not need this commodity at all.
- **mTLS between components.** Distinct concern (service-mesh territory). Not addressed here.
- **Certificate chain / trust-anchor injection.** cert-manager's `additionalOutputFormats` field is not exposed in v1; add when a use case surfaces.
