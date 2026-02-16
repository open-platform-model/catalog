@if(test)

package security

// =============================================================================
// Encryption Trait Tests
// =============================================================================

// Test: Encryption component helper with defaults
_testEncryptionComponent: #Encryption & {
	metadata: name: "encryption-test"
	spec: encryption: {
		atRest:    true
		inTransit: true
	}
}

// Test: Encryption with custom values
_testEncryptionCustom: #Encryption & {
	metadata: name: "encryption-custom"
	spec: encryption: {
		atRest:    false
		inTransit: true
	}
}
