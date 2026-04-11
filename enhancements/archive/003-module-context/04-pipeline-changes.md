# Pipeline Changes

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-25       |
| **Authors** | OPM Contributors |

---

## End-to-End Flow

```
ModuleRelease (CUE)
  metadata: { name, namespace, uuid }
  #module: <module definition>
  #env: env.#Environment       // carries #platform + environment #ctx
  values: { ... }

  → #ContextBuilder computes _computedCtx from:
      #env.#platform.#ctx (#PlatformContext, Layer 2)
      + #env.#ctx (#EnvironmentContext, Layer 3)
      + metadata (Layer 4) + component keys
  → let unifiedModule = #module & {
        #config: values
        #ctx:    _computedCtx
    }
  → components: { for name, comp in unifiedModule.#components { (name): comp } }

CLI (Go)
  → ParseModuleRelease() loads the CUE value
  → #env is imported by the release file; no CLI FillPath injection for environment
  → Extracts #env.#platform.#provider (composed transformer registry)
  → Evaluate unifiedModule.components
  → For each (component, transformer) pair:
      injectContext() fills #context in the transformer with #TransformerContext data
      (unchanged from current behavior)
  → Execute transformer → collect output resources
```

---

## `#ModuleRelease` Changes (CUE)

The `#ModuleRelease` definition targets an `#Environment` via `#env` (see `03-schema.md`). The `#ContextBuilder` receives the platform and environment from `#env` and merges them with release identity to produce `#ModuleContext`.

```cue
// catalog/core/v1alpha1/modulerelease/module_release.cue
#ModuleRelease: {
    ...

    #env: environment.#Environment

    let _computedCtx = (helpers.#ContextBuilder & {
        #release:     { name: metadata.name, namespace: metadata.namespace, uuid: metadata.uuid }
        #module:      { name: #moduleMetadata.name, version: #moduleMetadata.version,
                        fqn: #moduleMetadata.fqn, uuid: #moduleMetadata.uuid }
        #components:  #module.#components
        #platform:    #env.#platform
        #environment: #env
    }).out

    let unifiedModule = #module & {
        #config: values
        #ctx:    _computedCtx
    }

    _autoSecrets: (schemas.#AutoSecrets & {#in: unifiedModule.#config}).out

    components: {
        for name, comp in unifiedModule.#components {
            (name): comp
        }
        if len(_autoSecrets) > 0 {
            "opm-secrets": (helpers.#OpmSecretsComponent & {#secrets: _autoSecrets}).out
        }
    }

    ...
}
```

The `platform` layer in `#ctx` is merged from `#env.#platform.#ctx.platform` and `#env.#ctx.platform` by the `#ContextBuilder`. Platform teams set platform-level extensions on the `#Platform` construct; environment operators can add environment-specific extensions on `#Environment`. No Go-side `FillPath` injection is needed for platform or environment context.

---

## Go Pipeline Changes (`cli/pkg/render/`)

### `ParseModuleRelease()` — environment import (no Go injection)

Enhancement 003 originally injected `#environment` via `FillPath` from CLI flags. With enhancement 008, the environment is imported by the release file as a CUE package (`#env: env.#Environment`). The CLI no longer needs to inject cluster or route domain values — they are resolved via the CUE import chain.

The `ParseModuleRelease()` function still loads the CUE value but no longer calls `FillPath` for `#environment`. Instead, it extracts `#env.#platform.#provider` to obtain the composed transformer registry for the matcher.

```go
// cli/pkg/module/parse.go (illustrative)
// FillPath injection for #environment is no longer needed.
// The release file imports #env, which carries platform + environment context.
// The CLI extracts the composed provider for the matcher:
provider := spec.LookupPath(cue.MakePath(cue.Def("env"), cue.Def("platform"), cue.Def("provider")))
```

### `injectContext()` — no change required

The existing `injectContext()` function in `execute.go` fills `#TransformerContext` into each transformer at render time. This behavior is unchanged. `#ctx` is resolved during CUE evaluation of the unified module, before the transformer loop runs. By the time `injectContext()` is called, `#ctx` has already been resolved and is embedded in the component value.

The relationship between `#ctx` and `#TransformerContext` — whether to unify them, extend one from the other, or keep them separate — is deferred to a future design.

---

## Content Hash Injection

`#ctx.runtime.components[name].hashes` is the intended home for immutable resource content hashes. The computation of these hashes requires the resolved component spec, which in turn requires `#config` to be filled with `values`. The order of operations is:

```
1. values fills #config
2. #ctx (including resourceName, dns) is computed and fills #ctx
3. Component specs are evaluated with concrete #config and #ctx
4. Content hashes are derived from the concrete configMap/secret data in component specs
5. Hashes are injected back into #ctx.runtime.components[name].hashes
```

Step 5 creates a circular dependency if done purely in CUE: `#ctx` must be present to derive component specs, but content hashes require the evaluated component specs. Two implementation strategies are available:

**Strategy A — Two-pass CUE evaluation**: `#ctx` is injected without hashes first. Component specs are evaluated. Hashes are computed from the resolved data, then `#ctx` is re-injected with hashes populated via a second `FillPath` call. Components that reference hashes (e.g., for constructing an immutable ConfigMap name in an env var) use the second pass result.

**Strategy B — Hash computation deferred to transformers**: `#ctx.runtime.components[name].hashes` is populated by Go code in `injectContext()` rather than in `#ContextBuilder`. The Go pipeline computes hashes from the resolved component spec before calling transformers, and injects them into the context at that point. This mirrors the Go-side injection pattern used elsewhere in the pipeline.

Strategy B is lower risk because it follows the existing pattern and avoids a second CUE evaluation pass. It is the recommended starting point. Strategy A can be adopted later if there is a strong need for components to reference their own hash values at definition time (e.g., to self-reference an immutable ConfigMap name in an environment variable).

---

## Release File — Operator Usage

A release file imports its target environment and references the module:

```cue
// releases/dev/jellyfin/release.cue
package jellyfin

import (
    jellyfin "opmodel.dev/jellyfin/v1alpha1@v1"
    env "opmodel.dev/config@v1/.opm/environments/dev"
)

#env: env.#Environment

metadata: {
    name:      "jellyfin"
    namespace: "media"  // overrides environment default namespace
}

#module: jellyfin.#Module

values: {
    port:        8096
    serviceType: "ClusterIP"
    storage: config: {
        type: "pvc"
        size: "20Gi"
    }
}
```

With this configuration, context resolves as:

- `#ctx.runtime.cluster.domain` → `"cluster.local"` (from platform)
- `#ctx.runtime.route.domain` → `"dev.local"` (from environment)
- `#ctx.runtime.release.namespace` → `"media"` (from release, overriding env default)
- `#ctx.runtime.release.name` → `"jellyfin"` (from release metadata)
- `#ctx.platform` → merged from platform and environment extensions

`publishedServerUrl` is derived automatically from `#ctx.runtime.route.domain` — no entry in `values` required.
