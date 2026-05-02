# Experiment 003 — `#Claim` full pipeline

Sandbox for enhancement [015-claims](../../enhancements/015-claims/). Proves the
015 Claim pipeline (component + module transformer dispatch, `requiresComponents`
gate, `#statusWrites` writeback, status consumption) end-to-end in pure CUE.

Sibling [002-platform-construct](../002-platform-construct/) is the foundation
this experiment extends — 002 already proves 014's matcher index, registry,
and component-scope dispatch; 003 fills in the writeback channel, the
module-scope dispatch, and the dual-scope render path.

Self-contained: zero imports, zero stdlib. Module path
`opmodel.dev/experiments/claims@v0`, language `v0.16.0`. Package name
`claims`.

## Layout

```text
003-claims/
├── README.md
├── cue.mod/module.cue
├── 00_types.cue              # regex primitives (copy from 002)
├── 10_resource.cue           # #Resource stub (copy from 002)
├── 11_trait.cue              # #Trait stub (copy from 002)
├── 12_claim.cue              # #Claim with metadata.fqn unification (CL-D4)
├── 13_context.cue            # #TransformerContext, component? optional
├── 20_transformer.cue        # ComponentTransformer + ModuleTransformer
│                             # both with #statusWrites? on #transform
├── 21_module.cue             # 8-slot #Module + CL-D18 hidden constraint
├── 22_platform.cue           # #PlatformBase + strict #Platform (copy from 002)
├── 24_module_release.cue     # #ModuleRelease wrapper (copy from 002)
├── 25_render.cue             # 4-phase pure-CUE pipeline
├── 30_fixtures.cue           # quartets + transformers + modules + releases
├── t01_module_eight_slots_tests.cue
├── t02_claim_quartet_unification_tests.cue
├── t03_defines_claims_fqn_binding_tests.cue
├── t04_component_transformer_required_claims_match_tests.cue
├── t05_module_transformer_gate_pass_tests.cue
├── t06_module_transformer_gate_block_tests.cue
├── t07_status_writeback_component_scope_tests.cue
├── t08_status_writeback_module_scope_tests.cue
├── t09_consumer_reads_status_tests.cue
├── t10_dual_scope_backup_tests.cue
├── t11_side_effect_only_claim_tests.cue
├── t12_topological_chain_tests.cue
├── t13_full_pipeline_tests.cue
├── n01_module_claim_fqn_collision_tests.cue
├── n02_defines_claims_fqn_mismatch_tests.cue
├── n03_unfulfilled_claim_tests.cue
└── n05_multi_module_fulfiller_tests.cue
```

## Tests

### Positive (`@if(test)`, run via `cue vet -c -t test ./...`)

| File | Anchors | Asserts |
| --- | --- | --- |
| `t01_module_eight_slots` | MS-D2 | `#Module` accepts the 8-slot shape (metadata, #config, debugValues, #components, #lifecycles, #workflows, #claims, #defines) |
| `t02_claim_quartet_unification` | CL-D6 | `_managedDatabaseClaim & {#spec: {engine: "postgres", version: "16"}}` unifies; `sizeGB` defaults to 10; FQN echoes |
| `t03_defines_claims_fqn_binding` | DEF-D2 | `_opmCoreModule.#defines.claims["...managed-database@v1"].metadata.fqn` matches; transformer kind discriminates `ModuleTransformer` |
| `t04_component_transformer_required_claims_match` | TR-D5 | postgres fires against `web` because `web.#claims.db.metadata.fqn` matches `requiredClaims` |
| `t05_module_transformer_gate_pass` | TR-D7 | K8up fires for Strix media (both components carry `#BackupTrait`); `#AnyComponentMatches` reports 2 bearers |
| `t06_module_transformer_gate_block` | TR-D7 | K8up does NOT fire when no component carries `#BackupTrait`; gate is a pre-fire gate, not a filter |
| `t07_status_writeback_component_scope` | CL-D15/16 | postgres `#statusWrites: db: {host, port, secretName}` → `#moduleReleaseWithStatus.#components.web.#claims.db.#status` |
| `t08_status_writeback_module_scope` | CL-D15/16 | `_dnsHostnameTransformer` (module-scope) writes module-level `edge.fqdn`; component-scope db.host stays correct |
| `t09_consumer_reads_status` | CL-D15 + full chain | Deployment env `DATABASE_HOST` resolves to host populated by postgres transformer |
| `t10_dual_scope_backup` | TR-D7, Example 7 | K8up Schedule lists both trait-bearing components as targets; reads `schedule`/`backend` from module-level claim |
| `t11_side_effect_only_claim` | 12-pipeline-changes.md | Schedule renders, but `#status` stays empty when fulfiller omits `#statusWrites` |
| `t12_topological_chain` | CL-D16 ordering | depth-1 chain — postgres writes `db.host`, deployment body reads it; both fire in single render |
| `t13_full_pipeline` | end-to-end | 4 outputs (Deployment + Service + Postgres CR + DNS Record), both component-scope and module-scope writebacks visible |

### Negative (per-tag, must FAIL `cue vet -c`)

| File | Tag | Anchor | Asserts (vet must FAIL) |
| --- | --- | --- | --- |
| `n01_module_claim_fqn_collision` | `test_negative_module_claim_collision` | CL-D18 | Two `#claims` entries with same FQN under different ids → `_noDuplicateModuleClaimFqn` count is `2 & 1` ⇒ `_\|_` |
| `n02_defines_claims_fqn_mismatch` | `test_negative_defines_fqn_mismatch` | DEF-D2 | `#defines.claims["wrong-fqn@v1"]: _backupClaim` (key vs `metadata.fqn` mismatch) ⇒ `_\|_` |
| `n03_unfulfilled_claim` | `test_negative_unfulfilled_claim` | matcher demand walker | Consumer with claim FQN not in any transformer's `requiredClaims` → `unmatched.claims` non-empty; force `0 & 1` |
| `n05_multi_module_fulfiller` | `test_negative_multi_module_fulfiller` | 014 D13 | Two `#ModuleTransformer`s for same `requiredClaims` FQN → `_invalid.claims` non-empty → strict `#Platform._noMultiFulfiller` ⇒ `_\|_` |

## Run

```bash
cd catalog/experiments/003-claims

# Format
cue fmt ./...

# Positives (all 13 must pass)
cue vet -c -t test ./...

# Negatives (each MUST fail with non-zero exit)
! cue vet -c -t test_negative_module_claim_collision ./...
! cue vet -c -t test_negative_defines_fqn_mismatch ./...
! cue vet -c -t test_negative_unfulfilled_claim ./...
! cue vet -c -t test_negative_multi_module_fulfiller ./...

# Showcase: dump the full rendered manifest set for the keystone consumer
cue eval -t test ./... -e _pipelineFixture.#outputs
```

## Render pipeline architecture (`25_render.cue`)

Four phases in a single CUE evaluation:

1. **Match (Phase 1, BASE).** Iterate `#composedTransformers`, split by `kind`.
   Component-scope pairs use `#SatisfiesComponent` (label/resource/trait) plus
   a new claim-FQN check (FQN-equality on `cmp.#claims.<id>.metadata.fqn`).
   Module-scope pairs use `#SatisfiesModule` (label + module-claim-FQN) plus
   the optional `#AnyComponentMatches` gate evaluating `requiresComponents`
   conjunctively per-component (TR-D7).

2. **Project writebacks (Phase 2).** For each fired transformer, walk its
   `requiredClaims` and resolve the consumer claim id by FQN-equality on the
   matched scope's `#claims` map. Aggregate into
   `_componentWritebacks: [cName]: [claimId]: _` and
   `_moduleWritebacks: [claimId]: _`.

3. **Inject via unification (Phase 3).** Define `#moduleReleaseWithStatus:
   #moduleRelease & { #module: { #claims: <patch>; #components: <patch> } }`.
   This is the writeback step — no mutation, just a self-referencing patch
   struct.

4. **Render (Phase 4, FINAL).** Re-dispatch every transformer against
   `#moduleReleaseWithStatus`. Phase 4's `#component` gets the post-injection
   value, so transformer bodies that read `#claims.<id>.#status.<field>` see
   populated values.

Topological correctness for depth-1 chains (writer transformer → reader
component body) is automatic: Phase 2 reads only `#statusWrites` (which
depends on `#spec` / `#context` / fixed inputs); Phase 4 reads `#status`
(downstream of Phase 3's injection). No structural cycle because the
writeback computation never references `#moduleReleaseWithStatus`.

## Findings (CUE evaluation surprises — lift back to enhancement docs)

These pure-CUE constraints surfaced during implementation. Each is a
candidate for inclusion in 015's docs (most likely
`12-pipeline-changes.md` or a new "CUE evaluation gotchas" section).

### F1 — Field-name shadowing in for-comprehensions

CUE rejects fields whose name matches a for-comprehension's loop variable:

```cue
for tFqn, t in m {
    "\(tFqn)": {
        tFqn: tFqn         // ERROR: "field not allowed"
    }
}
```

Workaround: rename the storage field (`_tfqn`, `_componentName`, etc.).
This is independent of the CUE definition closure rules — the error is
emitted even when the parent struct is open. It surfaces in 003's
`_componentFiresBase` / `_moduleFiresBase` per-fire entries.

### F2 — Self-reference in unification field assignments

A struct literal `{X: <expr>}` where `<expr>` references the name `X`
resolves to the inner field, not the outer scope's variable:

```cue
#PlatformRender: {
    #moduleRelease!: _
    _result: t.#transform & {
        #moduleRelease: #moduleRelease    // self-reference, leaves field open
    }
}
```

The result is `_result.#moduleRelease == _` (open), with the body's
if-guards reading `_|_` and silently NOT firing. Workaround: capture the
outer scope via `let` (`let _release = #moduleRelease`) and reference the
let-binding in the unification.

This affected component-scope AND module-scope dispatchers in 003. The
fix is straightforward but the failure mode is silent (assertions like
`X & _result.output.metadata.name` still pass via `X & _ == X`), so it
is high-priority to document.

### F3 — Optional-field reference under strict mode

`cue vet -c` rejects direct reference to `?:`-declared fields. This
showed up when the experiment first used `sizeGB?: int & >=1 | *10`:

```
cannot reference optional field: sizeGB
```

Workaround: drop the `?` when a default is supplied
(`sizeGB: int & >=1 | *10`). Future production schemas can keep `?` only
when the field has no default and consumers never read it before
populating it.

### F4 — `t.#transform` body fires correctly only with concrete inputs

When a transformer body has `if X != _|_ { #statusWrites: ...; output: ... }`
guards and `t` is accessed via a typed map (`#TransformerMap`), the body
fires only after `t.#transform & { concrete inputs }` unification. This
is the existing 002 Finding 6/7/8 territory — 003 confirms the if-guard
+ inline-context pattern is sufficient.

### F5 — Struct-with-conditional-fields pattern is fragile

The pattern

```cue
let _gateOk = {
    if A { ok: true }
    if !A { ok: ... }
}
if _gateOk.ok { body }
```

did NOT correctly gate dispatch in 003's first iteration (module-scope
transformer never fired even when both branches should have produced
`ok: true`). Replacing with a single boolean `let`:

```cue
let _gateNeeded = A
let _gate = #SomePredicate & { ... }
if !_gateNeeded || _gate._ok { body }
```

works reliably. Cause not fully diagnosed; possibly related to F2's
scoping rules in let-bound struct bodies.

## Lift checklist

Items below should be applied back to enhancement 015's docs before its
schemas land in `catalog/core/v1alpha2/`.

- [ ] **F1 — field shadowing** — add to 015's `12-pipeline-changes.md` or a new "CUE evaluation gotchas" appendix.
- [ ] **F2 — let-capture for unification** — add to 015's `12-pipeline-changes.md` (production Go pipeline isn't affected, but pure-CUE renders need this).
- [ ] **F3 — optional field defaults** — propagate to 015's `03-schema.md` (`#Claim.#spec` quartet examples should default rather than `?:` when defaults exist).
- [ ] **F5 — gate evaluation pattern** — add to 015's `07-claim-fulfilment.md` near the `requiresComponents` discussion.
- [ ] **R1 confirmation** — depth-1 chains work in pure CUE; depth-2+ are confirmed Go-side responsibility. Update 015's R1 / 12-pipeline-changes.md.
- [ ] **R2 — claim id resolution** — fixture authors must walk `#component.#claims` by FQN-eq to find the consumer's claim id. Production schema may inject `#matchedClaimIds` to simplify. Open question: lift as a refinement to 015's `#statusWrites` definition.

## Cross-references

| Document | Purpose |
| --- | --- |
| [`002-platform-construct/`](../002-platform-construct/) | Sibling experiment for 014. Foundation that 003 extends. |
| [`015-claims/03-schema.md`](../../enhancements/015-claims/03-schema.md) | Canonical schemas for `#Claim`, `#ComponentTransformer.requiredClaims`, `#ModuleTransformer`, `#defines.claims` |
| [`015-claims/07-claim-fulfilment.md`](../../enhancements/015-claims/07-claim-fulfilment.md) | `#ModuleTransformer` schema + `requiresComponents` semantics + dual-scope worked example |
| [`015-claims/12-pipeline-changes.md`](../../enhancements/015-claims/12-pipeline-changes.md) | Pipeline contract for `#statusWrites`, topological sort, side-effect-only fulfilment |
| [`015-claims/08-examples.md`](../../enhancements/015-claims/08-examples.md) | Example 1 (managed-database) + Example 7 (dual-scope backup) — drive `_consumerWebApp` and `_consumerStrixMedia` |
