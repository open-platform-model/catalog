@if(test)

package dockerconfigjson

// Basic case: registry + username + password produce the expected
// .dockerconfigjson string. Field order matches kubelet's expected layout
// (CUE's json.Marshal preserves insertion order from the source).
//
// Oracle: base64("alice:s3cret") = "YWxpY2U6czNjcmV0".
_testBasicGhcr: (#DockerConfigJSON & {
	registry: "ghcr.io"
	username: "alice"
	password: "s3cret"
}).out & #"""
	{"auths":{"ghcr.io":{"username":"alice","password":"s3cret","auth":"YWxpY2U6czNjcmV0"}}}
	"""#

// Docker Hub registry uses a URL form as its key — the helper does not
// rewrite or normalise it, the caller chooses.
//
// Oracle: base64("bob:hunter2") = "Ym9iOmh1bnRlcjI=".
_testBasicDockerHub: (#DockerConfigJSON & {
	registry: "https://index.docker.io/v1/"
	username: "bob"
	password: "hunter2"
}).out & #"""
	{"auths":{"https://index.docker.io/v1/":{"username":"bob","password":"hunter2","auth":"Ym9iOmh1bnRlcjI="}}}
	"""#

// Self-hosted registry with port — common Harbor / Zot pattern.
//
// Oracle: base64("svc:p4ss") = "c3ZjOnA0c3M=".
_testBasicHarborWithPort: (#DockerConfigJSON & {
	registry: "harbor.internal:5000"
	username: "svc"
	password: "p4ss"
}).out & #"""
	{"auths":{"harbor.internal:5000":{"username":"svc","password":"p4ss","auth":"c3ZjOnA0c3M="}}}
	"""#
