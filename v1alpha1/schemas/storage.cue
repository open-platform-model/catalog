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
	nfs?:             #NFSVolumeSourceSchema
	cifs?:            #CIFSVolumeSourceSchema

	// Exactly one volume source must be set
	matchN(1, [
		{emptyDir!: _},
		{persistentClaim!: _},
		{configMap!: _},
		{secret!: _},
		{hostPath!: _},
		{nfs!: _},
		{cifs!: _},
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

// NFS volume source - mounts a directory from an NFS server
#NFSVolumeSourceSchema: {
	server!:   string // NFS server hostname or IP (e.g. "10.10.0.2")
	path!:     string // Exported NFS path (e.g. "/mnt/data/minecraft")
	readOnly?: bool
}

// CIFS/SMB volume source - mounts a share via the SMB CSI driver (smb.csi.k8s.io)
// Requires the SMB CSI driver to be installed on the cluster.
// Credentials are read from a K8s Secret with keys "username" and "password".
#CIFSVolumeSourceSchema: {
	source!:    string // UNC path to the SMB share (e.g. "//10.10.0.2/minecraft")
	secretRef!: string // Name of the K8s Secret containing cifs username + password
	readOnly?:  bool
}

// Persistent claim specification
#PersistentClaimSchema: {
	size:         string
	accessMode:   "ReadWriteOnce" | "ReadOnlyMany" | "ReadWriteMany" | *"ReadWriteOnce"
	storageClass: string | *"standard"
}
