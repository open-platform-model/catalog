module: "opmodel.dev/providers@v0"
language: {
	version: "v0.15.0"
}
source: {
	kind: "self"
}
deps: {
	"cue.dev/x/k8s.io@v0": {
		v:       "v0.6.0"
		default: true
	}
	"opmodel.dev/core@v0": {
		v: "v0.1.26"
	}
	"opmodel.dev/resources@v0": {
		v: "v0.2.25"
	}
	"opmodel.dev/schemas/kubernetes@v0": {
		v: "v0.0.2"
	}
	"opmodel.dev/schemas@v0": {
		v: "v0.1.13"
	}
	"opmodel.dev/traits@v0": {
		v: "v0.1.37"
	}
}
