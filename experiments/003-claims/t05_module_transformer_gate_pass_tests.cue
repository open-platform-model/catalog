@if(test)

package claims

// T05 — TR-D7 requiresComponents pre-fire gate, pass case.
// Strix media has app + db, both bearing #BackupTrait. K8up's gate
// (requiresComponents.traits has backup-trait FQN) finds matching
// components → gate passes → transformer fires.

_t05_platform: #Platform & {
	metadata: name: "t05"
	type: "kubernetes"
	#registry: {
		"opm-core": {#module: _opmCoreModule}
		"k8up": {#module: _k8upModule}
	}
}

_t05_render: #PlatformRender & {
	#platform:      _t05_platform
	#moduleRelease: _strixMediaRelease
}

_t05_moduleFires: {for k in _t05_render.#status.moduleFires {(k): _}}

t05_k8upFired: true & (_t05_moduleFires["opmodel.dev/k8up/v1alpha2/transformers/backup-schedule-transformer@v1"] != _|_)

// AnyComponentMatches reports both bearers.
_t05_gate: #AnyComponentMatches & {
	moduleRelease: _strixMediaRelease
	rc: traits: (_backupTrait.metadata.fqn): _
}
t05_gateOk:           true & _t05_gate._ok
t05_gateMatchesCount: 2 & len(_t05_gate._matches)
