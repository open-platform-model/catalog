@if(test)

package schemas

import (
	tst "experiments.dev/test-framework/testkit"
)

#tests: tst.#Tests & {

	// =========================================================================
	// #VolumeSchema
	// =========================================================================

	"#VolumeSchema": [
		{
			name:       "emptyDir"
			definition: #VolumeSchema
			input: {
				name: "tmp"
				emptyDir: {
					medium:    "memory"
					sizeLimit: "1Gi"
				}
			}
			assert: valid: true
		},
		{
			name:       "persistent"
			definition: #VolumeSchema
			input: {
				name: "data"
				persistentClaim: {
					size:         "50Gi"
					accessMode:   "ReadWriteOnce"
					storageClass: "ssd"
				}
			}
			assert: valid: true
		},
		{
			name:       "configMap"
			definition: #VolumeSchema
			input: {
				name: "config"
				configMap: data: "app.conf": "key=value"
			}
			assert: valid: true
		},
		{
			name:       "secret"
			definition: #VolumeSchema
			input: {
				name: "certs"
				secret: {
					type: "kubernetes.io/tls"
					data: {
						"tls.crt": "base64cert"
						"tls.key": "base64key"
					}
				}
			}
			assert: valid: true
		},
	]

	// =========================================================================
	// #VolumeMountSchema
	// =========================================================================

	"#VolumeMountSchema": [
		{
			name:       "minimal"
			definition: #VolumeMountSchema
			input: {
				name:      "data"
				mountPath: "/data"
			}
			assert: valid: true
		},
		{
			name:       "full"
			definition: #VolumeMountSchema
			input: {
				name:      "config"
				mountPath: "/etc/config"
				subPath:   "app.conf"
				readOnly:  true
			}
			assert: valid: true
		},
	]

	// =========================================================================
	// #PersistentClaimSchema
	// =========================================================================

	"#PersistentClaimSchema": [
		{
			name:       "defaults"
			definition: #PersistentClaimSchema
			input: size:   "10Gi"
			assert: valid: true
		},
		{
			name:       "ReadWriteMany"
			definition: #PersistentClaimSchema
			input: {
				size:         "100Gi"
				accessMode:   "ReadWriteMany"
				storageClass: "nfs"
			}
			assert: valid: true
		},
		{
			name:       "ReadOnlyMany"
			definition: #PersistentClaimSchema
			input: {
				size:       "50Gi"
				accessMode: "ReadOnlyMany"
			}
			assert: valid: true
		},
	]

	// =========================================================================
	// #VolumeBaseSchema
	// =========================================================================

	"#VolumeBaseSchema": [
		{
			name:       "defaults"
			definition: #VolumeBaseSchema
			input: name:   "base-volume"
			assert: valid: true
		},
	]
}
