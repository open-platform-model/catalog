package schemas

/////////////////////////////////////////////////////////////////
//// Volume Schemas
/////////////////////////////////////////////////////////////////

// Volume mount specification - defines container mount point
#VolumeMountSchema: {
	#VolumeSchema

	mountPath!: string
	subPath?:   string
	readOnly:   bool | *false
}

#FileMode: int & >=0 & <=511

#SecretVolumeItemSchema: {
	key!:  string
	path!: string
	mode?: #FileMode
}

#SecretVolumeSourceSchema: {
	from!: #Secret
	items?: [...#SecretVolumeItemSchema]
	defaultMode?: #FileMode
	optional?:    bool | *false
}

// Volume specification - defines storage source
#VolumeSchema: {
	name!: string

	// Only one of these can be set - defines the type of volume
	emptyDir?:        #EmptyDirSchema
	persistentClaim?: #PersistentClaimSchema
	configMap?:       #ConfigMapSchema
	secret?:          #SecretVolumeSourceSchema
	hostPath?:        #HostPathSchema

	// Exactly one volume source must be set
	matchN(1, [
		{emptyDir!: _},
		{persistentClaim!: _},
		{configMap!: _},
		{secret!: _},
		{hostPath!: _},
	])

	mountPath?: string
	subPath?:   string
	readOnly:   bool | *false
}

// EmptyDir specification
#EmptyDirSchema: {
	medium?:    *"node" | "memory"
	sizeLimit?: string
}

// HostPath specification - mounts a file or directory from the host node
#HostPathSchema: {
	path!: string
	type?: *"" | "DirectoryOrCreate" | "Directory" | "FileOrCreate" | "File" | "Socket" | "CharDevice" | "BlockDevice"
}

// Persistent claim specification
#PersistentClaimSchema: {
	size:         string
	accessMode:   "ReadWriteOnce" | "ReadOnlyMany" | "ReadWriteMany" | *"ReadWriteOnce"
	storageClass: string | *"standard"
}
