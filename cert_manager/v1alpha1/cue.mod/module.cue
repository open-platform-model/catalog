module: "opmodel.dev/cert_manager/v1alpha1@v1"
language: {
	version: "v0.15.0"
}
source: {
	kind: "self"
}
deps: {
	"cue.dev/x/crd/cert-manager.io@v0": {
		v: "v0.3.0"
	}
	"opmodel.dev/core/v1alpha1@v1": {
		v: "v1.3.6"
	}
	"opmodel.dev/opm/v1alpha1@v1": {
		v: "v1.5.6"
	}
}
