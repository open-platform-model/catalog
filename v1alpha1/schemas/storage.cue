package schemas

/////////////////////////////////////////////////////////////////
//// Volume Schemas
/////////////////////////////////////////////////////////////////

// Base schema - only shared field is name
#VolumeBaseSchema: {
	name!: string
	...
}

// Volume specification - defines storage source
#VolumeSchema: #VolumeBaseSchema & {
	emptyDir?: {
		medium?:    *"node" | "memory"
		sizeLimit?: string
	}
	persistentClaim?: #PersistentClaimSchema
	configMap?:       #ConfigMapSchema
	secret?:          #SecretSchema
}

// Volume mount specification - defines container mount point
#VolumeMountSchema: #VolumeBaseSchema & {
	mountPath!: string
	subPath?:   string
	readOnly?:  bool | *false
}

// Persistent claim specification
#PersistentClaimSchema: {
	size:         string
	accessMode:   "ReadWriteOnce" | "ReadOnlyMany" | "ReadWriteMany" | *"ReadWriteOnce"
	storageClass: string | *"standard"
}
