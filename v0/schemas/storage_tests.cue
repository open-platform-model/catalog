@if(test)

package schemas

// =============================================================================
// Storage Schema Tests
// =============================================================================

// ── VolumeSchema ─────────────────────────────────────────────────

_testVolumeEmptyDir: #VolumeSchema & {
	name: "tmp"
	emptyDir: {
		medium:    "memory"
		sizeLimit: "1Gi"
	}
}

_testVolumePersistent: #VolumeSchema & {
	name: "data"
	persistentClaim: {
		size:         "50Gi"
		accessMode:   "ReadWriteOnce"
		storageClass: "ssd"
	}
}

_testVolumeConfigMap: #VolumeSchema & {
	name: "config"
	configMap: {
		data: {
			"app.conf": "key=value"
		}
	}
}

_testVolumeSecret: #VolumeSchema & {
	name: "certs"
	secret: {
		type: "kubernetes.io/tls"
		data: {
			"tls.crt": "base64cert"
			"tls.key": "base64key"
		}
	}
}

// ── VolumeMountSchema ────────────────────────────────────────────

_testVolumeMountMinimal: #VolumeMountSchema & {
	name:      "data"
	mountPath: "/data"
}

_testVolumeMountFull: #VolumeMountSchema & {
	name:      "config"
	mountPath: "/etc/config"
	subPath:   "app.conf"
	readOnly:  true
}

// ── PersistentClaimSchema ────────────────────────────────────────

_testPersistentClaimDefaults: #PersistentClaimSchema & {
	size: "10Gi"
	// accessMode defaults to "ReadWriteOnce"
	// storageClass defaults to "standard"
}

_testPersistentClaimRWX: #PersistentClaimSchema & {
	size:         "100Gi"
	accessMode:   "ReadWriteMany"
	storageClass: "nfs"
}
