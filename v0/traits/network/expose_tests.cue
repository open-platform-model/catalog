@if(test)

package network

// =============================================================================
// Expose Trait Tests
// =============================================================================

// Test: ExposeTrait definition structure
_testExposeTraitDef: #ExposeTrait & {
	metadata: {
		apiVersion: "opmodel.dev/traits/network@v0"
		name:       "expose"
		fqn:        "opmodel.dev/traits/network@v0#Expose"
	}
}

// Test: Expose component helper
_testExposeComponent: #Expose & {
	metadata: name: "expose-test"
	spec: expose: {
		ports: http: {
			name:       "http"
			targetPort: 80
		}
		type: "ClusterIP"
	}
}

// Test: Expose with LoadBalancer
_testExposeLoadBalancer: #Expose & {
	metadata: name: "expose-lb"
	spec: expose: {
		ports: {
			http: {
				name:       "http"
				targetPort: 80
			}
			https: {
				name:       "https"
				targetPort: 443
			}
		}
		type: "LoadBalancer"
	}
}

// Test: ExposeDefaults has ClusterIP type
_testExposeDefaults: #ExposeDefaults & {
	type: "ClusterIP"
	ports: http: {
		name:       "http"
		targetPort: 80
	}
}
