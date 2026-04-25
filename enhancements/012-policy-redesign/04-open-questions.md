# Open Questions

Everything unresolved as of the first brainstorm. Each item carries the current disposition and what would move the needle.

---

## OQ-1 — Primitive count for cross-component concerns

**Question.** Does the shared-noun concern earn its own primitive name (`#Scope`), reuse the existing `#Resource` primitive one scope up (Option C.2), or get subsumed into a richer relation model (Option D)?

**Current disposition.** Unresolved. The three live candidates are Option A (new `#Scope`), Option C.2 (reuse `#Resource` nested inside `#Policy`), and Option D (relations / edges).

**What would move the needle.**

- A decision on OQ-2 (directed/asymmetric relations). If directed relations are in, Option D is the honest answer. If out, the choice narrows to A vs C.2.
- A sketch of how the authoring experience *feels* for each approach on 3–5 realistic commodities (not just shared-network). Readability in code beats abstract symmetry.
- A sketch of how tooling (`opm release preview`, diff, ownership graphs) looks for each. If D unlocks useful queries A/C cannot answer, that is a concrete argument for D.

---

## OQ-2 — Are asymmetric / directed cross-component relations in scope?

**Question.** Does OPM need to model directed, asymmetric relations between components (e.g. "A ships logs to B", "A reads from B", "A depends on B")?

**Current disposition.** Undecided. All of A, B, C, E assume symmetric set-membership only. Only D handles directed relations natively.

**What would move the needle.**

- Concrete authoring examples where an author *wants* to state a directed relation and today has to flatten it into per-component config. Candidates: log flows, observability pipelines, message-bus topic ownership, service-mesh authorization.
- Clarity on whether data-plane contracts (values flowing between components) are in scope for 012 or deferred entirely. 011 explicitly deferred them.
- Whether the existing `dependsOn` / workflow concepts in OPM already cover "A depends on B" well enough to not need a generic directed relation.

---

## OQ-3 — Where does membership live: on the component, or on the policy?

**Question.** Both central membership (`#Policy.appliesTo`) and distributed membership (component opt-in via mixin) are viable. Which is authoritative? Are both allowed?

**Current disposition.** Unresolved. Both variants were modeled for Options A and C. Trait-style opt-in reads natural for shared things the component knows about (network, volume); central selection reads natural for governance the platform imposes (security constraint).

**What would move the needle.**

- Author-experience test: which style makes each commodity (shared-net, shared-storage, security rule, backup, routing) read best?
- Decide whether to support one or both. Supporting both requires a conflict-resolution rule (what if a component opts in *and* is excluded by a policy's `appliesTo`?).
- Clarity on whether platform teams or module authors own the membership decision for each concern kind.

---

## OQ-4 — Lifecycle of the shared "noun"

**Question.** Does the shared entity live and die with an individual `#Policy`, or does it outlive any one policy at module scope?

**Current disposition.** **Decided for now** — removing the owning `#Policy` should remove the shared noun. This rules out Variant C.1 (module-level `#resources`) and pushes toward A or C.2.

**What would re-open it.**

- A concrete use case where a shared thing needs to outlive a specific policy — e.g. a module-level shared identity that several policies reference, or a shared volume pool consumed by multiple, independent policies.
- Multi-policy ownership of the same noun (two policies need the same network boundary) — would require either ref-counting or elevating the noun above the policy level.

---

## OQ-5 — What to do with `#PolicyRule`

**Question.** `#PolicyRule` today is half-baked: `enforcement.platform?: _` has no concrete enforcement path. Options:

1. Rename to `#Rule`, keep as-is, ship a concrete enforcement mechanism in a future enhancement.
2. Rename to `#Rule`, give it a `#RuleTransformer` scope that renders constraints into Kyverno / OPA / admission webhooks.
3. Drop it entirely — governance becomes just another flavor of directive with no distinct type.
4. Collapse rule + directive into a single primitive (Option B / E).

**Current disposition.** Unresolved. Depends on OQ-1.

**What would move the needle.**

- A concrete worked example of an enforced rule end-to-end (author → render → admission controller). 011 has three worked examples for `#Directive`; `#PolicyRule` has none.
- Decide whether "constraint" is a first-class grammar or a degenerate directive.

---

## OQ-6 — Does the renamed-or-replaced primitive break existing code?

**Question.** `#PolicyRule` is named in the current codebase (`core/v1alpha1/primitives/policy_rule.cue`, `core/v1alpha1/policy/policy.cue`, `core/v1alpha1/INDEX.md`). A rename to `#Rule` is mechanical; replacing it with a new shape is not.

**Current disposition.** Not a blocker for the design exploration, but the convergence doc must include a migration plan.

**What would move the needle.**

- Inventory of all current `#PolicyRule` usage in the catalog and `opm_experiments`. The `opm_experiments/v1alpha1/directives/k8up_backup.cue` uses `#Directive`; no actual `#PolicyRule` uses found during initial search.
- Decide whether the `#PolicyRuleSchema` RBAC schema (at `catalog/opm/v1alpha1/schemas/security.cue`) should be renamed in passing to avoid continued confusion with the primitive. It is a separate, unrelated thing.

---

## OQ-7 — Interaction with 011's `#Directive` + `#PolicyTransformer`

**Question.** If 012 lands a new primitive (`#Scope` or `#Relation`), does it coexist with 011's `#Directive`, subsume it, or force it to evolve?

**Current disposition.** The intent is coexistence: 011's render path for verb-flavor concerns is load-bearing and should survive. Options A and C.2 are additive — they add the noun flavor alongside `#Directive`. Option D is disruptive — `#Relation` potentially replaces `#Directive` as well.

**What would move the needle.**

- For each candidate approach: a re-render of one 011 example (backup, TLS, or routing) in that approach's idioms. Keeps 011's proven shape honest against the proposed change.
- A statement on whether 012 is purely additive or is allowed to refactor 011.

---

## OQ-8 — Do we need a component-side "membership" concept at all?

**Question.** If the answer to OQ-3 is "membership is expressed on the policy via `appliesTo`," then the component-opt-in variants (A.2, C with `#AttachedTo`) are unnecessary. If the answer is "both," then component-side mixins are load-bearing and need their own shape.

**Current disposition.** Unresolved — the brainstorm noted that trait-style opt-in reads natural for some concerns but did not decide.

**What would move the needle.**

- A trait-analogue shape for membership: what does a `#Member` / `#AttachedTo` mixin look like structurally? Is it a degenerate `#Trait` with a reference field, or a new mixin kind?
- Decide whether membership *is a trait* structurally — "the component has the trait of belonging to scope X." That would unify two concepts.

---

## OQ-9 — Naming

**Question.** If we keep a distinct primitive for the noun flavor, what should it be called?

- `#Scope` — historically accurate but carries KubeVela / OAM baggage.
- `#Scope` renamed to avoid confusion with provider/platform scope (module scope vs component scope).
- Something new: `#Shared`, `#Hyperedge`, `#Group`, `#Boundary`, `#Commune`, `#Topology`.

**Current disposition.** Unresolved. Naming is downstream of OQ-1.

**What would move the needle.**

- Decide OQ-1 first. If we land on a new primitive, pick a name that reads well in `#Policy.#<plural>` context: `#Policy.#scopes: ...` vs `#Policy.#boundaries: ...` vs `#Policy.#groups: ...`.

---

## OQ-10 — Multiple scopes per policy

**Question.** If a `#Policy` can carry multiple scopes (Option A), do multiple scopes on the same policy imply all members partake in all scopes? What if scopes conflict (two network boundaries, one policy)?

**Current disposition.** Not analyzed. Examples so far show one scope per policy.

**What would move the needle.**

- Decide whether `#Policy.#scopes` is `[fqn]: #Scope` (map keyed on FQN, one per kind) or `[name]: #Scope` (map keyed on name, multiple per kind allowed).
- Concrete case where an author wants two scopes of the same kind in one policy. Harder to find than it sounds.
