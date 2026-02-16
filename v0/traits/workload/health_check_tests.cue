@if(test)

package workload

// =============================================================================
// HealthCheck Trait Tests
// =============================================================================

// Test: HealthCheckTrait definition structure
_testHealthCheckTraitDef: #HealthCheckTrait & {
	metadata: {
		apiVersion: "opmodel.dev/traits/workload@v0"
		name:       "health-check"
		fqn:        "opmodel.dev/traits/workload@v0#HealthCheck"
	}
}

// Test: HealthCheck component with HTTP probes
_testHealthCheckHTTPComponent: #HealthCheck & {
	metadata: name: "hc-http-test"
	spec: healthCheck: {
		livenessProbe: {
			httpGet: {
				path: "/healthz"
				port: 8080
			}
		}
		readinessProbe: {
			httpGet: {
				path: "/ready"
				port: 8080
			}
		}
	}
}

// Test: HealthCheck component with exec probes
_testHealthCheckExecComponent: #HealthCheck & {
	metadata: name: "hc-exec-test"
	spec: healthCheck: {
		livenessProbe: {
			exec: command: ["pg_isready"]
		}
	}
}
