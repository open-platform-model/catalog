@if(test)

package schemas

import (
	tst "experiments.dev/test-framework/testkit"
)

#tests: tst.#Tests & {

	// =========================================================================
	// #SecurityContextSchema
	// =========================================================================

	securityContext: [
		{
			name:       "defaults"
			definition: "#SecurityContextSchema"
			input: {
				runAsNonRoot:             true
				readOnlyRootFilesystem:   false
				allowPrivilegeEscalation: false
			}
			assert: valid: true
		},
		{
			name:       "full"
			definition: "#SecurityContextSchema"
			input: {
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
			assert: valid: true
		},
		{
			name:       "permissive"
			definition: "#SecurityContextSchema"
			input: {
				runAsNonRoot:             false
				readOnlyRootFilesystem:   false
				allowPrivilegeEscalation: true
			}
			assert: valid: true
		},
		{
			name:       "default drop capabilities"
			definition: "#SecurityContextSchema"
			input: capabilities: drop: ["ALL"]
			assert: valid: true
		},
	]

	// =========================================================================
	// #WorkloadIdentitySchema
	// =========================================================================

	workloadIdentity: [
		{
			name:       "minimal"
			definition: "#WorkloadIdentitySchema"
			input: name:   "my-service-account"
			assert: valid: true
		},
		{
			name:       "full"
			definition: "#WorkloadIdentitySchema"
			input: {
				name:           "my-sa"
				automountToken: true
			}
			assert: valid: true
		},
	]
}
