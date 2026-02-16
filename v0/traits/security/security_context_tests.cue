@if(test)

package security

// =============================================================================
// SecurityContext Trait Tests
// =============================================================================

// Test: SecurityContext component helper with defaults
_testSecurityContextComponent: #SecurityContext & {
	metadata: name: "secctx-test"
	spec: securityContext: {
		runAsNonRoot:             true
		readOnlyRootFilesystem:   true
		allowPrivilegeEscalation: false
	}
}

// Test: SecurityContext with full options
_testSecurityContextFull: #SecurityContext & {
	metadata: name: "secctx-full"
	spec: securityContext: {
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
}
