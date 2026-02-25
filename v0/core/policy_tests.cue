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
		"test.dev/resources@v0#Container": #Resource & {
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
		}
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

// Test: policy with runtime mode
_testPolicyRuleModeRuntime: #PolicyRule & {
	metadata: {
		apiVersion: "test.dev/policies@v0"
		name:       "runtime-mode-rule"
	}
	enforcement: {
		mode:        "runtime"
		onViolation: "audit"
	}
	#spec: runtimeModeRule: {
		enabled: bool
	}
}

// Test: policy with all enforcement modes
_testPolicyAllModes: #Policy & {
	metadata: {
		name: "all-modes-policy"
	}
	#rules: {
		"test.dev/policies@v0#TestRule": #PolicyRule & {
			metadata: {
				apiVersion: "test.dev/policies@v0"
				name:       "test-rule"
			}
			enforcement: {
				mode:        "both"
				onViolation: "warn"
			}
			#spec: testRule: {
				value: int
			}
		}
	}
	appliesTo: {
		matchLabels: {
			"app": "test"
		}
	}
	spec: testRule: value: 10
}

// Test: policy FQN (should inherit from policy rule if needed)
_testPolicyFQN: #Policy & {
	metadata: {
		name: "my-policy"
	}
	#rules: {
		(_testPolicyRuleMinimal.metadata.fqn): _testPolicyRuleMinimal
	}
	appliesTo: {
		matchLabels: {
			"app": "test"
		}
	}
	spec: testRule: enabled: true
}

// Negative tests moved to testdata/*.yaml files
