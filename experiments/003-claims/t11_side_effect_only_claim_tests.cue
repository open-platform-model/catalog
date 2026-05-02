@if(test)

package claims

// T11 — Side-effect-only Claim: fulfiller renders an output but does NOT
// emit #statusWrites. The Claim's #status stays empty. Validates the
// 12-pipeline-changes.md "side-effect-only fulfilment" contract.
//
// _consumerSideEffectOnly carries module-level #claims.nightly: _backupClaim
// (which has no #status pin). _k8upBackupScheduleTransformer matches and
// renders a Schedule, but its #transform body omits #statusWrites entirely.

_t11_platform: #Platform & {
	metadata: name: "t11"
	type: "kubernetes"
	#registry: {
		"opm-core": {#module: _opmCoreModule}
		"k8up": {#module: _k8upModule}
	}
}

_t11_render: #PlatformRender & {
	#platform:      _t11_platform
	#moduleRelease: _sideEffectRelease
}

// K8up DID fire (output rendered).
_t11_moduleFires: {for k in _t11_render.#status.moduleFires {(k): _}}
t11_k8upFired: true & (_t11_moduleFires["opmodel.dev/k8up/v1alpha2/transformers/backup-schedule-transformer@v1"] != _|_)

// Schedule rendered.
_t11_schedule:    _t11_render.#outputs["opmodel.dev/k8up/v1alpha2/transformers/backup-schedule-transformer@v1"]
t11_scheduleKind: "Schedule" & _t11_schedule.kind

// But injectedModule is empty for nightly (no #statusWrites emitted).
t11_injectedEmpty: 0 & len([for k, _ in _t11_render.#status.injectedModule {k}])

// And the module-level claim's #status was NOT populated.
t11_nightlyStatusUnset: true & (_t11_render.#moduleReleaseWithStatus.#module.#claims.nightly.#status == _|_)
