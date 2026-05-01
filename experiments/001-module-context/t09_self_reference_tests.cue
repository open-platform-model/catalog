@if(test)

package module_context

// T09 — Self-reference via #names. A static component reads its own
// resourceName / DNS variants via #names without retyping the map key.
// This is the motivating case for D32.

_t09_module: #Module & {
	metadata: {
		modulePath: "opmodel.dev/experiments/modules"
		name:       "router-only"
		version:    "0.1.0"
		uuid:       "00000000-0000-0000-0000-000000000910"
	}
	#components: {
		"router": {
			// Bring #names into the component literal's lexical scope so the
			// body can reference it. Concrete value still injected by builder.
			#names: _

			metadata: name: "router"
			spec: {
				env: SELF_FQDN: {
					name:  "SELF_FQDN"
					value: #names.dns.fqdn
				}
			}
		}
	}
}

_t09_release: #ModuleRelease & {
	metadata: {
		name:      "rel"
		namespace: "ns"
		uuid:      "00000000-0000-0000-0000-000000000901"
	}
	#env:    _envDev
	#module: _t09_module
	values: {}
}

t09_self_fqdn: _t09_release.components.router.spec.env.SELF_FQDN.value & "rel-router.ns.svc.cluster.local"
