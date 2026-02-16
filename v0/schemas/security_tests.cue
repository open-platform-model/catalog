@if(test)

package schemas

// =============================================================================
// Security Schema Tests
// =============================================================================

// ── SecurityContextSchema ────────────────────────────────────────

_testSecurityContextDefaults: #SecurityContextSchema & {
	// Verify default values unify correctly
	runAsNonRoot:             true
	readOnlyRootFilesystem:   false
	allowPrivilegeEscalation: false
}

_testSecurityContextFull: #SecurityContextSchema & {
	runAsNonRoot:             true
	runAsUser:                1000
	runAsGroup:               1000
	readOnlyRootFilesystem:   true
	allowPrivilegeEscalation: false
	capabilities: {
		add: ["NET_BIND_SERVICE"]
		drop: ["ALL"]
	}
}

_testSecurityContextPermissive: #SecurityContextSchema & {
	runAsNonRoot:             false
	readOnlyRootFilesystem:   false
	allowPrivilegeEscalation: true
}

// ── WorkloadIdentitySchema ───────────────────────────────────────

_testWorkloadIdentityMinimal: #WorkloadIdentitySchema & {
	name: "my-service-account"
}

_testWorkloadIdentityFull: #WorkloadIdentitySchema & {
	name:           "my-sa"
	automountToken: true
}

// =============================================================================
// Negative Tests
// =============================================================================

// Negative tests moved to testdata/*.yaml files

// Test capabilities.drop default
_testSecurityContextDefaultDrop: #SecurityContextSchema & {
	capabilities: {
		drop: ["ALL"]
	}
}

// Negative tests moved to testdata/*.yaml files
