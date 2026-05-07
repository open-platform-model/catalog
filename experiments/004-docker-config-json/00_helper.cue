package dockerconfigjson

import (
	"encoding/base64"
	"encoding/json"
)

// #DockerConfigJSON computes the canonical .dockerconfigjson string for a
// single registry's credentials. Drop the result into a #SecretSchema with
// type: "kubernetes.io/dockerconfigjson" under data[".dockerconfigjson"].
//
// The output is the JSON form expected by the kubelet:
//
//   {"auths":{"<registry>":{"username":"...","password":"...","auth":"<b64>"}}}
//
// The `auth` field is base64(standard) of "username:password" — kubelet
// accepts either `auth` or `username`+`password`, but supplying both matches
// what `kubectl create secret docker-registry` produces and is widely
// compatible with image pull tooling.
//
// Multi-registry: call once per registry and merge the resulting JSON
// objects at the consumer level. Keeping this helper single-registry avoids
// embedding map-construction concerns in a low-level builder.
#DockerConfigJSON: {
	registry!: string
	username!: string
	password!: string
	email?:    string

	// auth = base64(username:password), standard alphabet, no URL escaping.
	_auth: base64.Encode(null, "\(username):\(password)")

	// email is omitted from output when absent rather than emitted as ""
	// — kubelet treats empty email as a present field.
	out: json.Marshal({
		auths: "\(registry)": {
			"username": username
			"password": password
			"auth":     _auth
			if email != _|_ {
				"email": email
			}
		}
	})
}
