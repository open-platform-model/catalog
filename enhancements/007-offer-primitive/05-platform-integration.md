# Platform Integration — `#Offer` Primitive

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-04-01       |
| **Authors** | OPM Contributors |

---

## Overview

`#Platform` (enhancement 008) composes providers into a unified transformer registry. With `#Offer`, the Platform also composes a unified offer registry, enabling claim/offer validation and capability reporting.

## Platform Gains `#composedOffers`

```cue
#Platform: {
	apiVersion: "opmodel.dev/core/v1alpha1"
	kind:       "Platform"

	metadata: {
		name!:        #NameType
		description?: string
	}

	kubeContext!: string
	kubeConfig?:  string
	context?:     #PlatformContext
	type!:        string

	#providers!: [...provider.#Provider]

	// Existing: composed transformer registry
	#composedTransformers: transformer.#TransformerMap & {
		for _, p in #providers {
			p.#transformers
		}
	}

	// NEW: composed offer registry
	#composedOffers: offer.#OfferMap & {
		for _, p in #providers {
			if p.#offers != _|_ {
				p.#offers
			}
		}
	}

	#provider: provider.#Provider & {
		metadata: {
			name:        metadata.name
			description: "Platform-composed provider"
			type:        type
			version:     "0.0.0"
		}
		#transformers: #composedTransformers
		#offers:       #composedOffers
	}

	// Auto-computed capabilities
	#declaredResources: #provider.#declaredResources
	#declaredTraits:    #provider.#declaredTraits
	#declaredClaims:    #provider.#declaredClaims
	#declaredOffers:    #provider.#declaredOffers       // NEW

	// Computed: which claim FQNs can this platform satisfy?
	#satisfiedClaims: [                                  // NEW
		for _, o in #composedOffers { o.satisfies }
	]
}
```

## Claim/Offer Validation

The Platform can validate that all claims in a module have a corresponding offer:

```cue
// Given a module's components with claims:
_moduleClaims: [
	for _, comp in module.#components {
		if comp.#claims != _|_ {
			for fqn, _ in comp.#claims { fqn }
		}
	}
]

// Unfulfilled claims: claims with no matching offer
_unfulfilledClaims: [
	for claimFQN in _moduleClaims
	if !list.Contains(platform.#satisfiedClaims, claimFQN) { claimFQN }
]
```

This extends enhancement 008's `unhandledClaims` (no transformer matched) with a higher-level check: is the capability even offered?

## Platform Capability Report

The CLI can generate a capability report from the platform's composed offers:

```text
$ opm platform capabilities prod

Platform: production (kubernetes)
Providers: opm, k8up, cert-manager, gateway-api, kubernetes

Capabilities:
  CLAIM                   STATUS    PROVIDED BY       IMPL VERSION
  backup@v1               offered   k8up              1.2.0
  restore@v1              offered   k8up              1.2.0
  certificate@v1          offered   cert-manager      1.5.0
  postgres@v1             offered   cnpg              1.0.0
  redis@v1                --        (none)            --
  s3@v1                   --        (none)            --

Transformers: 23 total (from 5 providers)
```

## Full Platform Example

```cue
import (
	core "opmodel.dev/core/v1alpha1/platform@v1"
	opm "opmodel.dev/opm/v1alpha1/providers/kubernetes"
	k8up "opmodel.dev/k8up/v1alpha1/providers/kubernetes"
	certmgr "opmodel.dev/cert_manager/v1alpha1/providers/kubernetes"
	gatewayapi "opmodel.dev/gateway_api/v1alpha1/providers/kubernetes"
	kubernetes "opmodel.dev/kubernetes/v1/providers/kubernetes"
)

platforms: {
	"prod": core.#Platform & {
		metadata: name: "production"
		type: "kubernetes"
		kubeContext: "admin@prod-cluster"
		context: {
			defaultDomain:       "example.com"
			defaultStorageClass: "gp3"
		}
		#providers: [
			opm.#Provider,           // OPM core (no offers, direct transformers)
			k8up.#Provider,          // backup + restore offers
			certmgr.#Provider,       // certificate offer
			gatewayapi.#Provider,    // gateway routing (no offers yet)
			kubernetes.#Provider,    // generic K8s catch-all (no offers)
		]
	}
}

// Platform auto-computes:
// #composedTransformers: all transformers from all 5 providers
// #composedOffers: backup, restore (from k8up) + certificate (from cert-manager)
// #satisfiedClaims: [backup@v1, restore@v1, certificate@v1]
// #declaredOffers: [k8up backup@v1, k8up restore@v1, certmgr certificate@v1]
```

## Deployment Validation Flow

```text
1. Module submitted for deployment:
   - Jellyfin module with #BackupClaim + #PostgresClaim

2. Platform offer check (NEW — pre-render validation):
   - backup@v1    -> offered by k8up      [OK]
   - postgres@v1  -> not offered           [WARN]

3. CLI output:
   warning: claim "postgres@v1" on component "jellyfin" has no matching offer
     in the current platform. Ensure external binding is provided in the release,
     or install a PostgreSQL capability provider.

4. Transformer matching (existing — render-time, from 008):
   - BackupClaim matches K8up's ScheduleTransformer  [OK]
   - PostgresClaim has no transformer                 [OK — data claim, external binding]

5. Rendering proceeds with warnings
```

The two validation layers complement each other:
- **Offer check** (this enhancement): "Is this capability available on the platform?"
- **Transformer check** (enhancement 008): "Can this claim be rendered to platform resources?"

Data claims may pass the transformer check (no transformer needed) but fail the offer check (no provider offers Postgres). This is the correct behavior — the CLI warns that external binding is required.
