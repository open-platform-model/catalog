# 001 — Module Context (`#ctx`) experiment

Sandbox for enhancement [016-module-context](../../enhancements/016-module-context/). Validates the proposed `#ctx` runtime-context channel — schemas, layered hierarchy, `#ContextBuilder`, per-component `#names` injection — as a self-contained CUE module before lifting any of it into `core/v1alpha2/`.

## Self-contained

**Zero imports.** No `core/v1alpha2/*`, no other catalog modules, no CUE stdlib (`uuid`, `strings`, `list`, …). Every file is in package `module_context` in this directory; identifier resolution is purely lexical within the package. UUIDs and FQNs are passed as opaque strings — the experiment proves the *context-handling* mechanics, not UUID derivation.

`cue.mod/module.cue` declares `module: "opmodel.dev/experiments/module_context@v0"` with no `deps:` block.

## Layout

```text
00_types.cue                Minimal regex-only type primitives
10_context.cue              #ModuleContext, #RuntimeContext, #ComponentNames, #PlatformContext, #EnvironmentContext
20_component.cue            Stub #Component with metadata.resourceName? + #names: #ComponentNames
21_module.cue               Stub #Module
22_platform.cue             Stub #Platform
23_environment.cue          #Environment
30_context_builder.cue      #ContextBuilder
40_module_release.cue       #ModuleRelease wiring
50_fixtures.cue             Concrete _platform / _env / _module fixtures (hidden)
tNN_*_tests.cue             11 test files (only loaded under `-t test`)
```

## What each test asserts

| File | Anchor decision(s) | What it proves |
|------|-----|-----|
| t01 | D8  | `cluster.domain` defaults to `cluster.local` when nothing overrides |
| t02 | D24 | env's `cluster.domain` beats platform's; release `metadata.namespace` beats env default |
| t03 | D9  | `route?` absent (`==_|_`) when env omits; concrete when env sets |
| t04 | D10 | Default `resourceName` = `{release}-{component}`; all four `dns.*` derive |
| t05 | D13 | `metadata.resourceName` override cascades through every `dns.*` variant |
| t06 | D32 | `#Component.#names == #ctx.runtime.components[<key>]` (lock-step) |
| t07 | D3, D28 | `#ctx.platform` carries open-struct merge of platform + env extensions |
| t08 | D6, "Before/After" | Component body reads `#ctx.runtime.route.domain` to compute Jellyfin-style URL |
| t09 | D32 | Component reads its own `#names.dns.fqdn` without retyping its map key |
| t10 | D32 | Dynamic `for ... in #config.servers` components get correct per-component `#names.dns.fqdn` |
| t11 | layer 3 | `#ctx.runtime.release.*` and `#ctx.runtime.module.*` populate verbatim |

## Run

```bash
cd catalog/experiments/001-module-context
cue fmt ./...
cue vet -c -t test ./...   # exits clean when every assertion passes
```

Each test field unifies `actual & expected`. A schema regression turns into a `conflicting values` error pointing at the offending test field.

## Findings vs. 016 03-schema.md

The experiment surfaced two places where the schema snippets in `03-schema.md` do not compile as written and need adjustment before lift into `core/v1alpha2/`:

### 1. Cluster-domain disjunction default chokes on optional env field

`03-schema.md` writes:

```cue
let _clusterDomain = *#environment.#ctx.runtime.cluster.domain |
    #platform.#ctx.runtime.cluster.domain
```

`#EnvironmentContext.runtime.cluster` is `cluster?:` — optional. When the env omits cluster (the common case), `#environment.#ctx.runtime.cluster.domain` is `_|_`, and CUE reports `cannot reference optional field: cluster` rather than gracefully falling through to the second disjunct.

Working form (`30_context_builder.cue`):

```cue
let _resolved = {
    domain: string
    if #environment.#ctx.runtime.cluster != _|_ {
        domain: #environment.#ctx.runtime.cluster.domain
    }
    if #environment.#ctx.runtime.cluster == _|_ {
        domain: #platform.#ctx.runtime.cluster.domain
    }
}
let _resolvedClusterDomain = _resolved.domain
```

### 2. Builder must receive components AFTER `#config: values` unification

`03-schema.md`:

```cue
let _builderOut = (#ContextBuilder & {
    ...
    #components:  #module.#components
    ...
}).out

let unifiedModule = #module & {
    #config:     values
    #ctx:        _builderOut.ctx
    #components: _builderOut.injections
}
```

`#module.#components` is read here *before* `#config` is unified into the module. Modules that build components dynamically from `#config` — the mc_java_fleet `for _srvName, _c in #config.servers { "server-\(_srvName)": ... }` pattern — produce no components in this view; the builder never sees them and `#ctx.runtime.components` is empty. Test t10 surfaces this.

Working form (`40_module_release.cue`):

```cue
let _withConfig = #module & {#config: values}
let _moduleComponents = _withConfig.#components
let _builderOut = (#ContextBuilder & {
    ...
    #components: _moduleComponents
    ...
}).out
let unifiedModule = _withConfig & {
    #ctx:        _builderOut.ctx
    #components: _builderOut.injections
}
```

### 3. Authoring-time `#ctx` / `#names` references need lexical scope

In real OPM modules, `#ctx` and `#names` are package-scoped via the `#Module` / `#Component` definitions in the module's source files, so component bodies can write `#ctx.runtime.route.domain` and `#names.dns.fqdn` directly. When inlining a `#Module & {...}` literal (as the experiment does for t08 / t09 / t10), CUE's lexical-scope resolution does **not** find `#ctx` / `#names` from the type definition; the literal must declare the field at its own level (`#ctx: _` / `#names: _`) to bring it into scope. Concrete value still arrives via `#ContextBuilder` unification.

This is not a schema bug — it's a CUE evaluation rule the documentation should mention so module authors writing modules-as-packages don't get tripped up if they ever try to inline a module literal in tests or docs.

### 4. `*_test.cue` is a reserved suffix; use `*_tests.cue`

`cue help inputs` notes "Files with names ending `_test.cue` are ignored for the time being; they are reserved for future testing functionality." Files must use `_tests.cue` (plural) — matches the existing cert_manager / k8up convention. Any future enhancement note about test files should call this out.

## Lift checklist (when promoting to core/v1alpha2)

- Apply both bugfixes (Findings 1 + 2) when copying `context_builder.cue` / `module_release.cue` into `core/v1alpha2/`.
- Restore stdlib imports (`uuid` for SHA1 derivation in `#Module.metadata.uuid` and `#ModuleRelease.metadata.uuid`).
- Add `metadata.resourceName?` to the real `#Component` (currently absent).
- Update `core/v1alpha2/module.cue` and `module_release.cue` to wire `#ctx` per the corrected pattern.
- Update the schema snippets in `enhancements/016-module-context/03-schema.md` so they reflect the working form, not the form that fails.
