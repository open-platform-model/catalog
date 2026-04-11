# Design Package: `#Offer` Primitive

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-04-01       |
| **Authors** | OPM Contributors |

## Summary

Introduce `#Offer` as a module-level primitive that declares what capabilities a module provides to the platform. An Offer is the counterpart to `#Claim` (enhancement 006): Claims declare what a component needs; Offers declare what a module provides. Claims and Offers always come in pairs — every well-known Claim has a corresponding well-known Offer definition. Multiple providers can implement the same Offer (e.g., K8up and Velero both implement `#BackupOffer`). Offers are linked to their corresponding Transformers, enabling capability providers to package controller, Offer, and Transformer together.

## Documents

1. [01-problem.md](01-problem.md) — No way to declare module capabilities; platform cannot validate claim fulfillment at install time
2. [02-design.md](02-design.md) — `#Offer` primitive definition, module integration, versioning, two flavors (capability and data)
3. [03-well-known-offers.md](03-well-known-offers.md) — Standard offer definitions paired with enhancement 006's well-known claims
4. [04-provider-integration.md](04-provider-integration.md) — How Offers link to Transformers and compose into Providers
5. [05-platform-integration.md](05-platform-integration.md) — How Platform aggregates Offers and validates claim fulfillment
6. [06-decisions.md](06-decisions.md) — All design decisions with rationale and alternatives considered
7. [notes.md](notes.md) — Deferred items and open discussion topics (PlatformCapability CRD, dependency chains)

## Applicability Checklist

- [x] `02-design.md` — New CUE definitions (`#Offer`, `#OfferMap`)
- [x] `04-provider-integration.md` — Impact on `#Provider` and `#Transformer`
- [x] `05-platform-integration.md` — Impact on `#Platform`
- [x] `notes.md` — Deferred items and open questions

## Cross-References

| Document | Purpose |
| -------- | ------- |
| `catalog/enhancements/006-claim-primitive/` | `#Claim` primitive — the demand-side counterpart to `#Offer` |
| `catalog/enhancements/008-platform-construct/` | `#Platform` construct — composes providers and their offers |
| `catalog/core/v1alpha1/provider/provider.cue` | `#Provider` definition — gains `#offers` and `#declaredOffers` |
| `catalog/core/v1alpha1/transformer/transformer.cue` | `#Transformer` definition — offers link to transformers |
| `catalog/core/v1alpha1/module/module.cue` | `#Module` definition — gains `#offers` field |
| `catalog/docs/design-principles.md` | OPM principles, especially II (Separation of Concerns) and III (Composability) |
