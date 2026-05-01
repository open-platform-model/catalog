@if(test)

package module_context

// T03 — route is optional. Present when env sets it; absent (or properly
// undefined) when env omits it. Anchors D9.

// Case A — env_dev sets route.domain. Builder propagates.
_t03a_release: #ModuleRelease & {
	metadata: {
		name:      "rel-a"
		namespace: "ns-a"
		uuid:      "00000000-0000-0000-0000-000000000301"
	}
	#env:    _envDev
	#module: _moduleDemo
	values: {}
}

t03a_routeDomain: _t03a_release.#resolvedCtx.runtime.route.domain & "dev.example.com"

// Case B — env_no_route does NOT set route. The conditional in #ContextBuilder
// must skip emitting `route`, so #ctx.runtime.route is absent.
// Assert by reading-via-_|_-comparison: route should not be defined.
_t03b_release: #ModuleRelease & {
	metadata: {
		name:      "rel-b"
		namespace: "ns-b"
		uuid:      "00000000-0000-0000-0000-000000000302"
	}
	#env:    _envNoRoute
	#module: _moduleDemo
	values: {}
}

// `_|_` (bottom) sentinel: a missing field unifies with nothing, so the
// expression `_t03b_release.#resolvedCtx.runtime.route` should be _|_
// (CUE error/missing). We assert the predicate `route == _|_` returns true.
t03b_routeAbsent: (_t03b_release.#resolvedCtx.runtime.route == _|_) & true
