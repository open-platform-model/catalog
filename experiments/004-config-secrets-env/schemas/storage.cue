package schemas

/////////////////////////////////////////////////////////////////
//// Volume Schemas
/////////////////////////////////////////////////////////////////

// Volume mount specification - defines container mount point
#VolumeMountSchema: {
	#VolumeSchema

	mountPath!: string
	subPath?:   string
	readOnly?:  bool | *false
}

// Volume specification - defines storage source
#VolumeSchema: {
	name!: string

	// Only one of these can be set - defines the type of volume
	emptyDir?:        #EmptyDirSchema
	persistentClaim?: #PersistentClaimSchema
	configMap?:       #ConfigMapSchema
	secret?:          #SecretSchema

	// Exactly one volume source must be set
	matchN(1, [
		{emptyDir!: _},
		{persistentClaim!: _},
		{configMap!: _},
		{secret!: _},
	])
}

// EmptyDir specification
#EmptyDirSchema: {
	medium?:    *"node" | "memory"
	sizeLimit?: string
}

// Persistent claim specification
#PersistentClaimSchema: {
	size:         string
	accessMode:   "ReadWriteOnce" | "ReadOnlyMany" | "ReadWriteMany" | *"ReadWriteOnce"
	storageClass: string | *"standard"
}
