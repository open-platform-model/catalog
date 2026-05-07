@if(test)

package dockerconfigjson

// When email is provided it appears in the auths entry. CUE evaluates the
// if-comprehension before the static field block, so `email` lands first
// in the marshalled output. Order does not matter to the kubelet — the
// test pins the actual ordering so any future CUE evaluator change shows
// up here rather than as a silent K8s diff.
//
// Oracle: base64("alice:s3cret") = "YWxpY2U6czNjcmV0".
_testWithEmail: (#DockerConfigJSON & {
	registry: "ghcr.io"
	username: "alice"
	password: "s3cret"
	email:    "alice@example.com"
}).out & #"""
	{"auths":{"ghcr.io":{"email":"alice@example.com","username":"alice","password":"s3cret","auth":"YWxpY2U6czNjcmV0"}}}
	"""#

// Without email, the field must be absent (not "" or null) so kubelet does
// not treat empty email as configured.
_testWithoutEmail: (#DockerConfigJSON & {
	registry: "ghcr.io"
	username: "alice"
	password: "s3cret"
}).out & #"""
	{"auths":{"ghcr.io":{"username":"alice","password":"s3cret","auth":"YWxpY2U6czNjcmV0"}}}
	"""#
