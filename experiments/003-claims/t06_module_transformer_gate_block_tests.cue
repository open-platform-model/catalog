@if(test)

package claims

// T06 — TR-D7 requiresComponents pre-fire gate, block case.
// _consumerStrixNoTrait has the backup claim but no #BackupTrait on any
// component. requiredClaims FQN matches at the module level, but the
// requiresComponents.traits gate finds no bearer → gate blocks → K8up
// transformer does NOT fire.
//
// This validates that requiresComponents is a PRE-FIRE gate (TR-D7), not a
// filter that drops some output. With requiredClaims matched but the gate
// closed, the transformer is silently skipped — no Schedule is rendered.

_t06_platform: #Platform & {
	metadata: name: "t06"
	type: "kubernetes"
	#registry: {
		"opm-core": {#module: _opmCoreModule}
		"k8up": {#module: _k8upModule}
	}
}

_t06_render: #PlatformRender & {
	#platform:      _t06_platform
	#moduleRelease: _strixNoTraitRelease
}

_t06_moduleFires: {for k in _t06_render.#status.moduleFires {(k): _}}

// K8up did NOT fire.
t06_k8upBlocked: true & (_t06_moduleFires["opmodel.dev/k8up/v1alpha2/transformers/backup-schedule-transformer@v1"] == _|_)

// Direct gate evaluation against the no-trait release reports zero matches.
_t06_gate: #AnyComponentMatches & {
	moduleRelease: _strixNoTraitRelease
	rc: traits: (_backupTrait.metadata.fqn): _
}
t06_gateOk:           false & _t06_gate._ok
t06_gateMatchesCount: 0 & len(_t06_gate._matches)
