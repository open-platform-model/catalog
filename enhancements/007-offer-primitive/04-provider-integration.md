# Provider Integration — `#Offer` Primitive

## Overview

Offers are linked to Transformers. This document describes how the link works and how Providers compose Offers into their transformer registries.

## The Bundling Pattern

A capability provider (K8up, Velero, cert-manager) ships everything in one package:

```text
K8up OPM Package
├── Module (operator components)
├── Offers (#BackupOffer, #RestoreOffer)
│   └── each Offer carries its Transformers
└── Provider (derived from Offers)
```

The Offer is the central artifact. It declares the capability AND carries the implementation.

### Offer Carries Transformers

```cue
import (
	ops "opmodel.dev/opm/v1alpha1/offers/ops@v1"
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
)

// K8up's implementation of the well-known #BackupOffer
#K8upBackupOffer: ops.#BackupOffer & {
	implVersion: "1.2.0"

	#transformers: {
		(#ScheduleTransformer.metadata.fqn):    #ScheduleTransformer
		(#PreBackupPodTransformer.metadata.fqn): #PreBackupPodTransformer
	}
}

// The transformers that implement the backup capability
#ScheduleTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/k8up/v1alpha1/providers/kubernetes/transformers"
		version:     "v1"
		name:        "schedule-transformer"
		description: "Generates K8up Schedule from backup claims"
	}
	requiredClaims: {
		(data.#BackupClaim.metadata.fqn): data.#BackupClaim
	}
	#transform: {
		#component: _
		#context:   transformer.#TransformerContext
		output: {
			apiVersion: "k8up.io/v1"
			kind:       "Schedule"
			// ... generate from #component.spec.backup
		}
	}
}
```

## Provider Gains `#offers`

`#Provider` gains an `#offers` field and derives its transformer registry from them:

```cue
#Provider: {
	// ... existing fields ...
	#transformers: transformer.#TransformerMap
	#offers?:      offer.#OfferMap              // NEW

	// Auto-computed: all offer FQNs this provider declares
	#declaredOffers: [                          // NEW
		for fqn, _ in (*#offers | {}) { fqn }
	]

	#declaredResources: [...]   // existing
	#declaredTraits:    [...]   // existing
	#declaredClaims:    [...]   // existing
	#declaredDefinitions: list.Concat([#declaredResources, #declaredTraits, #declaredClaims, #declaredOffers])
}
```

### Provider Derives Transformers from Offers

A capability provider's transformers come from its offers. The Provider unifies offer transformers into its transformer registry:

```cue
#K8upProvider: provider.#Provider & {
	metadata: {
		name:        "k8up"
		description: "K8up backup and restore provider"
		type:        "kubernetes"
		version:     "1.0.0"
	}

	#offers: {
		(#K8upBackupOffer.metadata.fqn):  #K8upBackupOffer
		(#K8upRestoreOffer.metadata.fqn): #K8upRestoreOffer
	}

	// Transformers derived from offers via CUE unification
	#transformers: {
		for _, o in #offers {
			if o.#transformers != _|_ {
				o.#transformers
			}
		}
	}
}
```

This is the formal link between Offer and Transformer. The Provider does not manually list transformers — they flow from Offers.

### Providers with Direct Transformers AND Offers

Some providers may have both offer-linked transformers and standalone transformers. The base Kubernetes provider has transformers that don't correspond to any offer (DeploymentTransformer, ServiceTransformer, etc.):

```cue
#KubernetesProvider: provider.#Provider & {
	metadata: {
		name:        "kubernetes"
		type:        "kubernetes"
		version:     "1.0.0"
		description: "Base Kubernetes provider"
	}

	// No offers — this is a base rendering provider
	// Transformers registered directly
	#transformers: {
		(deployment_t.metadata.fqn): deployment_t
		(service_t.metadata.fqn):    service_t
		(pvc_t.metadata.fqn):        pvc_t
		// ...
	}
}
```

The base provider has no offers because its transformers don't satisfy claims — they render resources and traits. Only capability providers (K8up, cert-manager, etc.) have offers.

## Data Offer Providers

Data offers (Postgres, Redis, S3) do not carry transformers. A data offer provider declares what data shapes it can provide:

```cue
#CnpgProvider: provider.#Provider & {
	metadata: {
		name:        "cnpg"
		type:        "kubernetes"
		version:     "1.0.0"
		description: "CloudNativePG PostgreSQL provider"
	}

	#offers: {
		(#CnpgPostgresOffer.metadata.fqn): #CnpgPostgresOffer
	}

	// No transformers — data offers provide values, not rendered resources
	#transformers: {}
}
```

Data offers are fulfilled through external binding (ModuleRelease values) or future cross-module wiring. The provider declares the capability; the fulfillment mechanism is separate.

## Offer/Transformer Relationship Summary

| Scenario | Offer | Transformers | Fulfillment |
|----------|-------|-------------|-------------|
| Operational capability (K8up backup) | `#BackupOffer` with `#transformers` | Derived from offer | Transformer renders platform resources |
| Data capability (CNPG Postgres) | `#PostgresOffer` with `#shape` | None | External binding or future cross-module |
| Base rendering (Kubernetes core) | None | Registered directly | Resource/Trait matching |
