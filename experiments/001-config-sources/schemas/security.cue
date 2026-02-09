package schemas

/////////////////////////////////////////////////////////////////
//// Security Schemas
/////////////////////////////////////////////////////////////////

#WorkloadIdentitySchema: {
	name!:           string
	automountToken?: bool | *false
}

// Security context constraints for container and pod-level hardening
#SecurityContextSchema: {
	// Run container as non-root user
	runAsNonRoot: bool | *true
	// Specific user ID to run as
	runAsUser?: int
	// Specific group ID to run as
	runAsGroup?: int
	// Mount the root filesystem as read-only
	readOnlyRootFilesystem: bool | *false
	// Prevent privilege escalation
	allowPrivilegeEscalation: bool | *false
	// Linux capabilities
	capabilities?: {
		add?: [...string]
		drop: [...string] | *["ALL"]
	}
}
