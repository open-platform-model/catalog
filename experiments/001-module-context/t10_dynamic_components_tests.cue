@if(test)

package module_context

// T10 — Dynamic component generation. mc_java_fleet-style:
//   for _srvName, _c in #config.servers { "server-\(_srvName)": ... }
// Each generated component reads its own #names.dns.fqdn from inside the loop.
// Anchors D32's mc_java_fleet motivation.

_t10_module: #Module & {
	metadata: {
		modulePath: "opmodel.dev/experiments/modules"
		name:       "fleet"
		version:    "0.1.0"
		uuid:       "00000000-0000-0000-0000-000000001010"
	}
	#config: {
		servers: [string]: {}
	}
	#components: {
		// Generate one component per server entry in #config.
		for _srvName, _c in #config.servers {
			"server-\(_srvName)": {
				#names: _
				metadata: name: "server-\(_srvName)"
				spec: {
					env: SELF_FQDN: {
						name:  "SELF_FQDN"
						value: #names.dns.fqdn
					}
				}
			}
		}
	}
}

_t10_release: #ModuleRelease & {
	metadata: {
		name:      "fleet"
		namespace: "games"
		uuid:      "00000000-0000-0000-0000-000000001001"
	}
	#env:    _envDev
	#module: _t10_module
	values: {
		servers: {
			lobby: {}
			arena: {}
		}
	}
}

t10_lobby_fqdn: _t10_release.components."server-lobby".spec.env.SELF_FQDN.value & "fleet-server-lobby.games.svc.cluster.local"
t10_arena_fqdn: _t10_release.components."server-arena".spec.env.SELF_FQDN.value & "fleet-server-arena.games.svc.cluster.local"

// Verify resourceName cascades correctly even when the component key is
// dynamically interpolated.
t10_lobby_resourceName: _t10_release.#resolvedCtx.runtime.components."server-lobby".resourceName & "fleet-server-lobby"
