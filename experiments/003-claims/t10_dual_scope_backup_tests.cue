@if(test)

package claims

// T10 — Example 7 keystone: dual-scope backup. Module-level BackupClaim +
// per-component BackupTrait + #ModuleTransformer with requiresComponents
// gate. Asserts the rendered K8up Schedule lists every trait-bearing
// component and reads spec from the module-level claim.

_t10_platform: #Platform & {
	metadata: name: "t10"
	type: "kubernetes"
	#registry: {
		"opm-core": {#module: _opmCoreModule}
		"k8up": {#module: _k8upModule}
	}
}

_t10_render: #PlatformRender & {
	#platform:      _t10_platform
	#moduleRelease: _strixMediaRelease
}

_t10_schedule: _t10_render.#outputs["opmodel.dev/k8up/v1alpha2/transformers/backup-schedule-transformer@v1"]

t10_kind:       "Schedule" & _t10_schedule.kind
t10_apiVersion: "k8up.io/v1" & _t10_schedule.apiVersion
t10_name:       "strix-prod-nightly" & _t10_schedule.metadata.name
t10_namespace:  "media" & _t10_schedule.metadata.namespace

// Spec reads from the module-level BackupClaim.
t10_schedule:    "0 2 * * *" & _t10_schedule.spec.schedule
t10_backend:     "offsite-b2" & _t10_schedule.spec.backend
t10_targetCount: 2 & len(_t10_schedule.spec.targets)
