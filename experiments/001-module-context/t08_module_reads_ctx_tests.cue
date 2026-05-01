@if(test)

package module_context

// T08 — Module body reads #ctx.runtime.route.domain to compute a URL,
// reproducing the Jellyfin "publishedServerUrl" example from
// 016 02-design.md "Before/After". Anchors the design's motivating case.

_t08_module: #Module & {
	// Declare #ctx at the literal level so references inside the components
	// body have it in lexical scope. The concrete value still comes from
	// #ModuleRelease via #ContextBuilder; this is just a scope-bringer.
	#ctx: _

	metadata: {
		modulePath: "opmodel.dev/experiments/modules"
		name:       "jelly"
		version:    "0.1.0"
		uuid:       "00000000-0000-0000-0000-000000000810"
	}
	#components: {
		"jelly-svc": {
			metadata: name: "jelly-svc"
			spec: {
				if #ctx.runtime.route != _|_ {
					env: PUBLISHED_URL: {
						name:  "PUBLISHED_URL"
						value: "https://jelly.\(#ctx.runtime.route.domain)"
					}
				}
			}
		}
	}
}

_t08_release: #ModuleRelease & {
	metadata: {
		name:      "jelly"
		namespace: "media"
		uuid:      "00000000-0000-0000-0000-000000000801"
	}
	#env:    _envDev
	#module: _t08_module
	values: {}
}

t08_publishedUrl: _t08_release.components."jelly-svc".spec.env.PUBLISHED_URL.value & "https://jelly.dev.example.com"
