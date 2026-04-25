# KubeVela Prior-Art Research

Context: OPM previously had `#Scope`, which was scrapped in favor of `#Policy` because KubeVela made the same move. This document captures what KubeVela actually did, why (as far as the record shows), and what the shift cost them.

## Timeline

| When | What |
|------|------|
| ~2020 | OAM spec defines `ApplicationScope` (grouping components by shared behavior: health, network). |
| PR [oam-dev/spec#140](https://github.com/oam-dev/spec/pull/140) | OAM spec extended to include a **network scope** for VPC assignment and subnet configuration. |
| 2021 — KubeVela [v1.0.0](https://github.com/kubevela/kubevela/releases/tag/v1.0.0) | Breaking change. `ApplicationScope`, `ScopeDefinition`, `HealthScope`, and the earlier `ApplicationConfiguration` construct **removed** from the runtime. Labeled "legacy code removal" in migration docs. Policies introduced simultaneously. |
| 2021 → present | Policy becomes the canonical mechanism for cross-component concerns: topology, override, shared-resource, health, security/RBAC. |

## Stated Rationale (What the Record Actually Says)

KubeVela maintainers **did not publish an explicit design document** explaining why Scope was discarded in favor of Policy. The closest on-record motivations:

1. **Issue [kubevela#1613](https://github.com/kubevela/kubevela/issues/1613)** — the feature request that introduced Policies — notes:

   > "there is no application-level configuration across components."

   Scope was per-component; traits were per-component. Policies were introduced to address application-wide concerns.

2. **CNCF blog (2023)** — KubeVela maintainers write they are "waiting for more feedback and evidence from industrial usage before proposing extra added concepts like Workflow or Policy to the OAM spec." Reveals a **pragmatism-over-specification-compliance** posture: Scope wasn't working in practice; Policy solved real problems.

3. **Migration guide** — lists removed objects with no rationale. The shift reads as a change in platform design philosophy: move from infrastructure-connected groupings (Scope) to **deployment governance** (Policy).

## What Policy Gained

Scope was **passive**: a grouping that operators interpreted and applied rules to out-of-band.

Policies are **active**: executable constraints rendered into the deployment pipeline, positioned after component rendering but before workflow execution.

Concretely:

- **Topology Policy** — explicit cluster/region selection + label-based filtering. Supersedes network scope's VPC assignment.
- **Override Policy** — environment-specific configuration differentiation (governance + configuration).
- **Shared-Resource Policy** — cross-application resource ownership and lifecycle management. A genuinely new capability.
- **Health Policy** — application-wide health probe configuration.
- **Security / RBAC Policies** — declarative RBAC rules, secret backends.

Policies transform the entire application delivery pipeline, not just organize metadata. That framing is load-bearing for platform engineers managing multi-cloud, multi-environment deployment.

## What Was Lost

No public community pushback is recorded. That is itself informative — either adoption of Scope was thin, or the removal didn't break real workflows in KubeVela's userbase. Either way, the following are gone or reduced:

1. **Explicit network scoping.** Scope's `network-id` / `subnet-id` / `gateway-type` properties have no direct Policy equivalent:
   - Multi-cluster topology → **topology + override policies** (selects clusters, not networks).
   - Within-cluster namespace placement → CUE-template `metadata.namespace`.
   - Pod affinity / topology → the **affinity trait** (pod-spec-level, not application-level).

2. **Co-location guarantees.** Scope allowed "these 5 components share a network boundary." Policy has no equivalent. Closest mechanisms:
   - Shared-Resource Policy — for *cross-app* shared infra, not intra-app set semantics.
   - Component orchestration with `dependsOn` — ordering, not co-location.
   - Ref-objects scope — restricts references to same namespace/cluster.

3. **HealthScope partially survives** as a read-only aggregation concept in documentation, but is no longer a first-class governance construct.

## How Cross-Component Non-Governance Concerns Are Now Modeled

The critical gap:

### Shared network requirements

- **OAM Scope model:** "All components in this NetworkScope can reach each other; the operator controls SDN rules."
- **KubeVela Policy model:** no direct equivalent.
  - Same-cluster components are implicitly network-reachable via Kubernetes Services.
  - Cross-cluster networking is handled by infrastructure (ClusterAPI, ServiceMesh), not modeled in Application.
  - Namespace-level isolation is controlled via `metadata.namespace` in CUE, not by policy.
  - Pod affinity is a per-component trait, not application-wide.

### Shared storage

- **OAM Scope model:** infrastructure-mediated grouping.
- **KubeVela model:** storage *trait* per component (PVC) + shared-resource policy for cross-app ConfigMap ownership. No "these components share a volume pool" at the app level.

### Implicit co-location

- **OAM Scope model:** "these components are in the same scope; infrastructure enforces proximity."
- **KubeVela model:** not directly expressible. Workarounds:
  - Force all components to the same cluster via topology policy.
  - Use `dependsOn` to sequence + rely on single-cluster scheduling.
  - Use pod-affinity trait to co-locate on same node.

## Interpretation For OPM

KubeVela's shift wasn't principled; it was **convergence on delivery governance** — the problem KubeVela's platform-engineer audience cared about. OAM Scopes were designed for infrastructure operators; KubeVela Policies serve platform engineers managing multi-cloud deployments.

The cost was real: loss of explicit cross-component infrastructure grouping semantics. Components can still share networks or storage, but it's implicit (same cluster, same namespace) or delegated to traits / infrastructure, not modeled at the application level.

**For OPM** — which models multi-cluster and multi-provider as first-class and defines its own module-level abstractions — the noun-flavor concerns matter more, not less. Copying KubeVela's move absorbs a blind spot that fit their audience but does not fit OPM's.

## Primary Sources

- [KubeVela Feature Issue #1613 — App-Level Policies](https://github.com/kubevela/kubevela/issues/1613)
- [OAM Spec — ApplicationScope](https://github.com/oam-dev/spec/blob/master/5.application_scopes.md)
- [OAM Spec PR #140 — Network Scope Addition](https://github.com/oam-dev/spec/pull/140)
- [KubeVela v1.0.0 Release Notes](https://github.com/kubevela/kubevela/releases/tag/v1.0.0)
- [KubeVela Migration Guide](https://kubevela.io/docs/platform-engineers/system-operation/migration-from-old-version/)
- [KubeVela Shared-Resource Policy](https://kubevela.io/docs/end-user/policies/shared-resource/)
- [CNCF Blog — KubeVela, Cloud-Native Application and Platform Engineering (2023)](https://www.cncf.io/blog/2023/03/31/kubevela-the-road-to-cloud-native-application-and-platform-engineering/)
- [KubeVela Design Doc — Workflow & Policy](https://github.com/kubevela/kubevela/blob/master/design/vela-core/workflow_policy.md)
