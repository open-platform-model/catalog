@if(test)

package dockerconfigjson

// Password containing JSON-hazardous characters: double-quote and backslash.
// CUE's json.Marshal escapes them; the raw-string oracle holds the literal
// post-escape bytes.
//
// Oracle: base64("alice:p\"a\\ss") = "YWxpY2U6cCJhXHNz"
//   (12 bytes: a l i c e : p " a \ s s)
_testPasswordWithQuotesAndBackslash: (#DockerConfigJSON & {
	registry: "ghcr.io"
	username: "alice"
	password: "p\"a\\ss"
}).out & #"""
	{"auths":{"ghcr.io":{"username":"alice","password":"p\"a\\ss","auth":"YWxpY2U6cCJhXHNz"}}}
	"""#

// Password with non-ASCII characters: UTF-8 passes through verbatim in the
// JSON output (no \uXXXX escaping); base64 encodes the UTF-8 byte sequence.
//
// Oracle: base64("alice:pässwörd") where ä=c3a4, ö=c3b6 in UTF-8.
_testPasswordWithUnicode: (#DockerConfigJSON & {
	registry: "ghcr.io"
	username: "alice"
	password: "pässwörd"
}).out & #"""
	{"auths":{"ghcr.io":{"username":"alice","password":"pässwörd","auth":"YWxpY2U6cMOkc3N3w7ZyZA=="}}}
	"""#
