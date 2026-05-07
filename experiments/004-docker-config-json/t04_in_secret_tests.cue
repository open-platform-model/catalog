@if(test)

package dockerconfigjson

// Integration shape: helper output dropped into a struct mimicking
// #SecretSchema. Proves the helper composes with the existing secrets
// pipeline — `out` is a string, fits anywhere a Secret data value goes.
//
// The real #SecretSchema in opmodel.dev/opm/v1alpha1/schemas accepts
// `data: [string]: #Secret | string`; the JSON output is a plain string,
// so it slots into the `string` arm without engaging the #Secret
// auto-discovery walker (which is correct — the dockerconfigjson is the
// payload, not a credential reference).
_testInSecretShape: {
	let _payload = (#DockerConfigJSON & {
		registry: "ghcr.io"
		username: "alice"
		password: "s3cret"
	}).out

	secret: {
		name:      "ghcr-creds"
		type:      "kubernetes.io/dockerconfigjson"
		immutable: false
		data: ".dockerconfigjson": _payload
	}
} & {
	secret: {
		name: "ghcr-creds"
		type: "kubernetes.io/dockerconfigjson"
		data: ".dockerconfigjson": #"""
			{"auths":{"ghcr.io":{"username":"alice","password":"s3cret","auth":"YWxpY2U6czNjcmV0"}}}
			"""#
	}
}
