@if(test)

package security

// =============================================================================
// WorkloadIdentity Trait Tests
// =============================================================================

// Test: WorkloadIdentity component helper
_testWorkloadIdentityComponent: #WorkloadIdentity & {
	metadata: name: "wid-test"
	spec: workloadIdentity: {
		name: "my-service-account"
	}
}

// Test: WorkloadIdentity with automount token
_testWorkloadIdentityAutoMount: #WorkloadIdentity & {
	metadata: name: "wid-automount"
	spec: workloadIdentity: {
		name:           "my-sa"
		automountToken: true
	}
}
