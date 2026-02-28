package schemas

/////////////////////////////////////////////////////////////////
//// Security Schemas
/////////////////////////////////////////////////////////////////

#WorkloadIdentitySchema: {
	name!:           string
	automountToken?: bool
}

// Security context constraints for container and pod-level hardening
#SecurityContextSchema: {
	// Run container as non-root user
	runAsNonRoot: bool
	// Specific user ID to run as
	runAsUser?: int
	// Specific group ID to run as
	runAsGroup?: int
	// Mount the root filesystem as read-only
	readOnlyRootFilesystem: bool
	// Prevent privilege escalation
	allowPrivilegeEscalation: bool
	// Linux capabilities
	capabilities?: {
		add?: [...string]
		drop: [...string] | ["ALL"]
	}
}

#EncryptionConfigSchema: {
	atRest:    bool
	inTransit: bool
}
