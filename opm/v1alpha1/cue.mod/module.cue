module: "opmodel.dev/opm/v1alpha1@v1"
language: {
	version: "v0.15.0"
}
source: {
	kind: "self"
}
deps: {
	"cue.dev/x/crd/cert-manager.io@v0": {
		v: "v0.2.0"
	}
	"cue.dev/x/k8s.io@v0": {
		v:       "v0.6.0"
		default: true
	}
	"opmodel.dev/core/v1alpha1@v1": {
		v: "v1.0.0"
	}
}
