# Problem Statement — `#Module` Flat Shape with `#Claim` and `#Api` Primitives

## Current State

`#Module` (`catalog/core/v1alpha1/module/module.cue`) currently exposes:

- `metadata` (identity, FQN, UUID, labels)
- `#components` (developer-defined components)
- `#policies` (developer- or platform-defined policies — rules and directives)
- `#config` (the value schema / API contract)
- `debugValues` (concrete example values for testing)

`#Resource`, `#Trait`, `#Blueprint`, `#PolicyRule`, `#Directive`, `#StatusProbe`, `#Op`, and `#Action` exist as primitives. `#Component`, `#Policy`, `#Lifecycle`, `#Workflow`, `#Status`, `#Bundle`, `#Provider`, `#Transformer` exist as constructs.

`#Module` doubles as both an **Application** (`#components` render to deployable resources via providers) and an **API description** (`#config` is the parameter schema; components describe what gets generated).

There is no primitive today that expresses an ecosystem-extensible "I need X" / "I provide X" pairing. Archived enhancements 006 and 007 introduced `#Claim` and `#Offer` along these lines but were never landed.

## Gap / Pain

### Module field-bloat risk

OPM's vision requires several more primitives at module level: needs (claims), provided APIs, lifecycles for operators, workflows for on-demand operations. Adding each as its own top-level field on `#Module` produces an unboundedly growing struct. Each new field forces a `#Module` schema change and adds cognitive load for module authors who must learn the full vocabulary even to write a small module.

### Resource and Claim litmus overlap

`catalog/docs/core/definition-types.md` lists both `#Resource` and a future `#Claim` as answering "what must exist?" That phrasing does not differentiate them. Without a sharper litmus, authors cannot tell whether to model a need as a `#Resource` (catalog-fixed, transformer-rendered) or a `#Claim` (ecosystem-extended, provider-fulfilled).

### No clean ecosystem extension surface

The vision distinguishes commodity services (well-known, agreed-upon platform APIs — Managed Database, Container, Volume, Backup) from specialty services (vendor innovation surface — VectorIndex, EventBus, custom platform APIs). Today, both would have to ship as `#Resource` in the catalog or as ad-hoc CRDs. Neither path lets a vendor publish a typed contract that other modules can request and that the platform can route — without a catalog PR for every new type.

### Operator-Module case has no clean expression

An admin deploying an operator Module to an OPM platform expects three things: the controller installs, the operator's CRDs register, and the operator declares which Claim types it fulfills (so other Modules' `#claims` can be matched to it). Today, `#components` covers controller + CRDs, but there is no place to declare "this Module fulfills `ManagedDatabase`."

### App/API duality lost on adornment growth

`#Module`'s App-vs-API duality already works elegantly via `#config` (App = parameterized via values; API = `#config` is the published schema). However, every new top-level adornment (Policy, Claim, Action, Lifecycle, …) blurs which fields apply in which mode and forces all consumers — App authors, Operator authors, API publishers — to read past fields they do not use.

## Concrete Example

A developer wants to ship a stateless web app that needs a Postgres database. A vendor wants to ship a Postgres operator that fulfills the well-known `ManagedDatabase` capability. A platform team wants to ship an API-only Module that declares a self-service `ImageRegistry` API surface.

Today, all three modules use the same `#Module` shape. The web app uses `#components`. The operator uses `#components` (controller + CRDs) but has no field to register "I fulfill `ManagedDatabase`." The API-only Module has only `#config` filled out — no signal that it is a published API rather than a deployable application. The ManagedDatabase capability itself has no canonical home — neither catalog Resource nor CRD captures the contract that a vendor's Module fulfills.

If we naively add `#claims`, `#apis`, `#lifecycles`, `#workflows`, `#offers`, `#actions` to `#Module`, the type grows to twelve+ top-level fields, half of which apply to one role only.

## Why Existing Workarounds Fail

- **Modeling claims as Resources.** Resources are catalog-fixed: adding `ManagedDatabase` requires a catalog PR plus a Transformer per provider. Vendors cannot self-publish.
- **Modeling provided APIs as CRDs only.** CRDs cover the k8s registration but not the OPM-platform-level contract: the self-service catalog has no entry, deploy-time matching has nothing to match against, and the schema is duplicated between the operator's CRD and any module that wants typed parameters.
- **Treating `#policies` as a catch-all bag.** `#Policy` was extended in enhancement 011 to carry `#PolicyRule` and `#Directive`. Stretching it further to carry needs and provided APIs muddies its semantics — `#Policy` is for governance and operational orchestration, not demand/supply pairing.
- **Adding kind discrimination to `#Module` (`#AppModule`, `#APIModule`, `#OperatorModule`).** Loses the deliberate flexibility of one type covering app + API + operator simultaneously. Also fragments tooling: every CLI command must know which kinds it handles.
