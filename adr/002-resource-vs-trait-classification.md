# ADR-002: Resource vs Trait Classification Criteria

## Status

Accepted (retroactive, 2026-03)

## Context

OPM defines two primitive types for composing components: Resources (independent deployable entities) and Traits (behavioral modifiers attached to a resource via `appliesTo`). The boundary between these two types was not formally defined, which led to WorkloadIdentity being initially classified as a Resource.

WorkloadIdentity describes a service identity for a workload — it configures a Kubernetes ServiceAccount and optionally binds it to an IAM role. As a Resource, it could exist independently in a component, but a WorkloadIdentity without a workload is meaningless. It does not represent a standalone deployable unit; it modifies how a workload authenticates.

This misclassification caused practical problems. The ServiceAccountTransformer matched WorkloadIdentity via `requiredResources`, which meant any component with a WorkloadIdentity was forced to also declare it as a standalone resource rather than as a behavioral property of the workload. Workload blueprints (StatelessWorkload, StatefulWorkload, etc.) could not naturally compose WorkloadIdentity because blueprint composition relies on the Resource/Trait distinction to determine how definitions attach to components.

## Decision

Reclassify WorkloadIdentity from a Resource to a Trait, and establish explicit criteria for the Resource/Trait boundary:

**A definition is a Resource when** it represents an independently meaningful, deployable entity. Removing all other definitions from the component should leave something that still makes sense to deploy. Examples: Container (a workload), ConfigMaps (configuration data), PersistentVolumeClaim (storage).

**A definition is a Trait when** it describes a behavioral characteristic of another definition and is meaningless in isolation. It must declare `appliesTo` to express which Resources it modifies. Examples: Scaling (modifies a workload), SecurityContext (modifies a workload), Expose (modifies a workload's networking).

WorkloadIdentity fits the Trait criteria: it describes *how a workload authenticates*, not *what is deployed*. Its FQN changed from `opmodel.dev/resources/security@v1#WorkloadIdentity` to `opmodel.dev/traits/security@v1#WorkloadIdentity`.

This decision also establishes a precedent: a Trait can trigger creation of standalone Kubernetes objects (in this case, a ServiceAccount). The fact that a trait's transformer emits an independent K8s resource does not make the OPM definition a Resource — the classification is about the modeling intent, not the output shape. Whether a ServiceAccount gets created is a provider concern, not a model concern.

**Alternatives considered:**

- **Keep WorkloadIdentity as a Resource and adjust blueprint composition.** This would preserve the existing classification but require blueprints to treat certain Resources as optional attachments rather than standalone entities, blurring the Resource/Trait boundary further. Rejected because it would erode the compositional model.

- **Introduce a third primitive type (e.g. "Mixin") for definitions that produce standalone objects but are behaviorally trait-like.** This would avoid the precedent of traits producing objects, but adds complexity to the type system for a single use case. Rejected per the Simplicity & YAGNI principle.

## Consequences

**Positive:** The Resource/Trait boundary now has explicit criteria that future contributors can apply when classifying new definitions. Blueprint composition works naturally — workload blueprints declare WorkloadIdentity as an optional trait via `appliesTo`, matching how SecurityContext and other behavioral modifiers already work. The ServiceAccountTransformer matches via `requiredTraits` instead of `requiredResources`, which correctly expresses that the transformer activates when a workload *has identity behavior*, not when an identity resource exists.

**Negative:** This was a breaking change — the FQN changed, all workload transformers had to move WorkloadIdentity from `requiredResources`/`optionalResources` to `optionalTraits`, and any downstream modules referencing the old FQN broke. The precedent that Traits can produce standalone K8s objects adds a subtlety to the model that may surprise contributors who expect Traits to only modify existing objects.

**Trade-off:** The classification criteria prioritize modeling intent over output shape. This makes the model more expressive and compositionally clean, but means you cannot determine a definition's type by looking at what its transformer produces — you have to understand the definition's role in the component.
