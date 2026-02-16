@if(test)

package workload

// =============================================================================
// Scaling Trait Tests
// =============================================================================

// Test: ScalingTrait definition structure
_testScalingTraitDef: #ScalingTrait & {
	metadata: {
		apiVersion: "opmodel.dev/traits/workload@v0"
		name:       "scaling"
		fqn:        "opmodel.dev/traits/workload@v0#Scaling"
	}
}

// Test: Scaling component helper with default count
_testScalingComponent: #Scaling & {
	metadata: name: "scaling-test"
	spec: scaling: count: 1
}

// Test: Scaling with high count
_testScalingHighCount: #Scaling & {
	metadata: name: "scaling-high"
	spec: scaling: count: 100
}

// Test: Scaling with autoscaling
_testScalingWithAuto: #Scaling & {
	metadata: name: "scaling-auto"
	spec: scaling: {
		count: 2
		auto: {
			min: 1
			max: 20
			metrics: [{
				type: "cpu"
				target: averageUtilization: 80
			}]
		}
	}
}

// Negative tests moved to testdata/*.yaml files
