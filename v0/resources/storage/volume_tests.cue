@if(test)

package storage

// =============================================================================
// Volume Resource Tests
// =============================================================================

// Test: VolumesResource definition structure
_testVolumesResourceDef: #VolumesResource & {
	metadata: {
		apiVersion: "opmodel.dev/resources/storage@v0"
		name:       "volumes"
		fqn:        "opmodel.dev/resources/storage@v0#Volumes"
	}
}

// Test: Volumes component helper
_testVolumesComponent: #Volumes & {
	metadata: name: "vol-test"
	spec: volumes: {
		data: {
			name: "data"
			persistentClaim: {
				size:       "10Gi"
				accessMode: "ReadWriteOnce"
			}
		}
	}
}

// Test: Volume with emptyDir
_testVolumesEmptyDir: #Volumes & {
	metadata: name: "emptydir-test"
	spec: volumes: {
		tmp: {
			name: "tmp"
			emptyDir: {
				medium:    "memory"
				sizeLimit: "100Mi"
			}
		}
	}
}

// Test: Volume with configMap
_testVolumesConfigMap: #Volumes & {
	metadata: name: "configmap-vol-test"
	spec: volumes: {
		config: {
			name: "config"
			configMap: data: "app.conf": "key=value"
		}
	}
}
