# Design — `#Offer` Primitive

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-04-01       |
| **Authors** | OPM Contributors |

---

## Design Goals

- Introduce `#Offer` as the supply-side counterpart to `#Claim`
- Every well-known Claim has a paired well-known Offer definition
- Multiple providers can implement the same Offer (K8up and Velero both implement `#BackupOffer`)
- Offer is module-level: a module declares the capabilities it provides to the platform
- Offer is linked to its Transformers: capability providers package controller + Offer + Transformer together
- Offer versioning matches Claim versioning: major version in FQN, optional implementation semver
- Modules can have both Claims (on components) and Offers (on module)
- Platform can aggregate Offers from all providers and validate claim fulfillment
- A future OPM controller and web UI can discover platform capabilities from Offer declarations

## Non-Goals

- PlatformCapability CRD design (deferred — see [notes.md](notes.md))
- Cross-module auto-wiring (Claim in Module A automatically bound to Offer in Module B)
- Dependency ordering or cycle detection across modules
- Data offer provisioning (e.g., auto-creating a Postgres instance from an Offer)
- Changes to the `#Claim` primitive itself

## High-Level Approach

`#Offer` is a new primitive in `core/v1alpha1/primitives/`. It follows the same metadata pattern as all OPM primitives (modulePath, version, name, fqn). An Offer declares which Claim FQN it satisfies and optionally carries linked Transformers (for capability offers) or a `#shape` (for data offers).

Offers compose into `#Module` via a new `#offers` field. When a capability provider (K8up, cert-manager) publishes a module, it includes the operator components AND the Offer declarations with their linked Transformers.

Offers also compose into `#Provider` via a new `#offers` field. The Provider derives its transformers from the offers it carries. The Platform aggregates offers from all composed providers, enabling claim/offer validation and capability reporting.

## Schema / API Surface

### `#Offer` Primitive

File: `core/v1alpha1/primitives/offer.cue`

```cue
package primitives

import (
	"strings"
	t "opmodel.dev/core/v1alpha1/types@v1"
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
)

// Offer declares what a module provides to the platform.
// The supply-side counterpart to #Claim.
#Offer: {
	apiVersion: "opmodel.dev/core/v1alpha1"
	kind:       "Offer"

	metadata: {
		modulePath!: t.#ModulePathType
		version!:    t.#MajorVersionType // Major version — must match paired Claim FQN version
		name!:       t.#NameType
		#definitionName: (t.#KebabToPascal & {"in": name}).out

		fqn: t.#FQNType & "\(modulePath)/\(name)@\(version)"
		description?: string
		labels?:      t.#LabelsAnnotationsType
		annotations?: t.#LabelsAnnotationsType
	}

	// Which claim this offer satisfies — the paired Claim's FQN
	satisfies!: t.#FQNType

	// Semver of the offer implementation (informational, within major version)
	// Allows providers to advertise their implementation maturity
	implVersion?: t.#VersionType

	// For capability offers: linked transformers that render this offer's claim
	#transformers?: transformer.#TransformerMap

	// For data offers: the shape this offer provides
	// Must be a superset of the paired claim's #shape
	#shape?: {...}
}

#OfferMap: [string]: #Offer
```

### Two Flavors

Offers mirror the two Claim flavors from enhancement 006:

| Flavor | Has `#transformers` | Has `#shape` | Example |
|--------|-------------------|-------------|---------|
| Capability offer | Yes | No | `#BackupOffer` — K8up renders K8up Schedule CRs |
| Data offer | No | Yes | `#PostgresOffer` — CloudNativePG provides connection details |

The flavor is implicit based on which optional fields are present. No explicit `type` field is needed.

### Versioning

Claim FQN: `opmodel.dev/opm/v1alpha1/claims/data/backup@v1` (major only — stable contract)
Offer FQN: `opmodel.dev/opm/v1alpha1/offers/ops/backup@v1` (major only — matches claim)

The `implVersion` field carries semver for the specific implementation:

```cue
#K8upBackupOffer: ops.#BackupOffer & {
	implVersion: "1.2.0"
	// ...
}
```

**Version compatibility rule:** An Offer's major version (in its FQN) must match the paired Claim's major version (in its FQN). The `satisfies` field enforces this — it references the exact Claim FQN including version.

When a provider supports multiple major versions of a claim, it publishes separate Offer definitions:

```cue
#K8upBackupOfferV1: ops.#BackupOfferV1 & { implVersion: "1.2.0" }
#K8upBackupOfferV2: ops.#BackupOfferV2 & { implVersion: "2.0.0" }
```

## Module Integration

`#Module` gains an `#offers` field:

```cue
#Module: {
	#components:  component.#ComponentMap
	#policies?:   policy.#PolicyMap
	#offers?:     offer.#OfferMap          // NEW
	#config:      _
	debugValues:  _
}
```

### Example: K8up Module

K8up packages controller, offers, and transformers together:

```cue
import (
	module "opmodel.dev/core/v1alpha1/module@v1"
	ops "opmodel.dev/opm/v1alpha1/offers/ops@v1"
)

k8upModule: module.#Module & {
	metadata: {
		modulePath: "opmodel.dev/k8up"
		name:       "k8up"
		version:    "1.0.0"
	}

	#components: {
		"operator": #StatelessWorkload & {
			spec: container: {
				image: "ghcr.io/k8up-io/k8up:v2"
				ports: [{name: "metrics", containerPort: 8080}]
			}
		}
	}

	#offers: {
		(#K8upBackupOffer.metadata.fqn):  #K8upBackupOffer
		(#K8upRestoreOffer.metadata.fqn): #K8upRestoreOffer
	}
}
```

### Example: Module with Both Claims and Offers

CloudNativePG offers Postgres but needs S3 for WAL archiving:

```cue
cnpgModule: module.#Module & {
	metadata: {
		modulePath: "opmodel.dev/cnpg"
		name:       "cnpg"
		version:    "1.0.0"
	}

	#components: {
		"operator": #StatelessWorkload & data.#S3Claim & {
			spec: {
				container: { image: "ghcr.io/cloudnative-pg/cloudnative-pg:1.22" }
				s3: {} // Platform fills S3 connection details
			}
		}
	}

	// I provide Postgres capability
	#offers: {
		(#CnpgPostgresOffer.metadata.fqn): #CnpgPostgresOffer
	}
}
```

This creates a dependency: CloudNativePG can only provide Postgres if S3 is available (from MinIO, Garage, or external binding).

## Before / After

### Before: No Capability Declaration

```cue
// K8up module — just components, no capability declaration
k8upModule: #Module & {
	#components: {
		"operator": #StatelessWorkload & { ... }
	}
}

// K8up provider — separate, manually maintained, no link to module
#K8upProvider: provider.#Provider & {
	#transformers: {
		(schedule_t.metadata.fqn): schedule_t
		(prebackup_t.metadata.fqn): prebackup_t
	}
}

// Platform has no way to report capabilities from installed modules
// CLI can only warn about unhandled claims AFTER rendering
```

### After: Explicit Capability Declaration

```cue
// K8up module — declares capabilities with linked transformers
k8upModule: #Module & {
	#components: {
		"operator": #StatelessWorkload & { ... }
	}
	#offers: {
		(#K8upBackupOffer.metadata.fqn):  #K8upBackupOffer
		(#K8upRestoreOffer.metadata.fqn): #K8upRestoreOffer
	}
}

// Offer carries its transformers — formal link
#K8upBackupOffer: ops.#BackupOffer & {
	implVersion: "1.2.0"
	#transformers: {
		(schedule_t.metadata.fqn):    schedule_t
		(prebackup_t.metadata.fqn):   prebackup_t
	}
}

// Provider derives transformers from offers
#K8upProvider: provider.#Provider & {
	#offers: {
		(#K8upBackupOffer.metadata.fqn):  #K8upBackupOffer
		(#K8upRestoreOffer.metadata.fqn): #K8upRestoreOffer
	}
	// #transformers derived from #offers
}

// Platform aggregates offers from all providers
// CLI validates claims against offers BEFORE rendering
// Future controller + web UI can query capabilities
```
