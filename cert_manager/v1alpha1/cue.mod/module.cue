module: "opmodel.dev/cert_manager/v1alpha1@v1"
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
	"opmodel.dev/core/v1alpha1@v1": {
		v: "v1.0.0"
	}
	"opmodel.dev/opm/v1alpha1@v1": {
		v: "v1.0.0"
	}
}
