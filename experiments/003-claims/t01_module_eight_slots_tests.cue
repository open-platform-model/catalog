@if(test)

package claims

// T01 — MS-D2: #Module accepts the eight-slot shape.
//
// Validates the experiment's `#Module` def by unifying with a value carrying
// every defined slot. The hidden CL-D18 constraint is exercised by N01.

_t01_eightSlotModule: #Module & {
	metadata: {
		modulePath: "example.com/test"
		name:       "eight-slot"
		version:    "0.1.0"
		fqn:        "example.com/test/eight-slot:0.1.0"
		uuid:       "00000000-0000-0000-0000-0000000000ee"
	}
	#config: {}
	debugValues: {}
	#components: web: {
		metadata: name: "web"
		spec: {
			image:    "nginx:latest"
			replicas: 1
		}
	}
	#lifecycles: {}
	#workflows: {}
	#claims: dns: _hostnameClaim & {
		#spec: name: "edge"
	}
	#defines: claims: {
		(_hostnameClaim.metadata.fqn): _hostnameClaim
	}
}

// Each slot present + concretely accessible.
t01_metadataName: "eight-slot" & _t01_eightSlotModule.metadata.name
t01_componentsCount: 1 & len([for _, _ in _t01_eightSlotModule.#components {true}])
t01_claimsCount: 1 & len([for _, _ in _t01_eightSlotModule.#claims {true}])
t01_definesClaims: 1 & len([for _, _ in _t01_eightSlotModule.#defines.claims {true}])
t01_lifecyclesCount: 0 & len([for _, _ in _t01_eightSlotModule.#lifecycles {true}])
t01_workflowsCount: 0 & len([for _, _ in _t01_eightSlotModule.#workflows {true}])
