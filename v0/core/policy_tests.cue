@if(test)

package core

// =============================================================================
// Policy & PolicyRule Definition Tests
// =============================================================================

// Test: minimal valid policy rule
_testPolicyRuleMinimal: #PolicyRule & {
	metadata: {
		apiVersion: "test.dev/policies@v0"
		name:       "test-rule"
	}
	enforcement: {
		mode:        "deployment"
		onViolation: "block"
	}
	#spec: testRule: {
		enabled: bool
	}
}

// Test: policy rule with all enforcement options
_testPolicyRuleFullEnforcement: #PolicyRule & {
	metadata: {
		apiVersion:  "test.dev/policies@v0"
		name:        "full-enforcement-rule"
		description: "Tests all enforcement settings"
	}
	enforcement: {
		mode:        "both"
		onViolation: "warn"
		platform: {
			engine: "kyverno"
		}
	}
	#spec: fullEnforcementRule: {
		maxReplicas: int
	}
}

// Helper component for policy tests
_testPolicyTargetComponent: #Component & {
	metadata: {
		name: "policy-target"
		labels: {
			"core.opmodel.dev/workload-type": "stateless"
		}
	}
	#resources: {
		"test.dev/resources@v0#Container": close(#Resource & {
			metadata: {
				apiVersion: "test.dev/resources@v0"
				name:       "container"
				labels: {
					"core.opmodel.dev/workload-type": "stateless"
				}
			}
			#spec: container: {
				name!:  #NameType
				image!: string
			}
		})
	}
	spec: container: {
		name:  "test"
		image: "nginx:latest"
	}
}

// Test: minimal valid policy
_testPolicyMinimal: #Policy & {
	metadata: {
		name: "minimal-policy"
	}
	#rules: {
		(_testPolicyRuleMinimal.metadata.fqn): _testPolicyRuleMinimal
	}
	appliesTo: {
		matchLabels: {
			"core.opmodel.dev/workload-type": "stateless"
		}
	}
	spec: testRule: enabled: true
}

// Test: policy with component reference
_testPolicyWithComponents: #Policy & {
	metadata: {
		name: "component-ref-policy"
	}
	#rules: {
		(_testPolicyRuleMinimal.metadata.fqn): _testPolicyRuleMinimal
	}
	appliesTo: {
		components: [_testPolicyTargetComponent]
	}
	spec: testRule: enabled: false
}
