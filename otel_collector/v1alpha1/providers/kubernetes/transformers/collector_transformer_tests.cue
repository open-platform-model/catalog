@if(test)

package transformers

// Test: minimal OpenTelemetryCollector (deployment mode)
_testCollectorMinimal: (#CollectorTransformer.#transform & {
	#component: {
		metadata: name: "gateway"
		spec: collector: {
			spec: {
				mode:     "deployment"
				replicas: 1
				config: {
					receivers: otlp: protocols: {
						grpc: endpoint: "0.0.0.0:4317"
						http: endpoint: "0.0.0.0:4318"
					}
					exporters: debug: {}
					service: pipelines: traces: {
						receivers: ["otlp"]
						exporters: ["debug"]
					}
				}
			}
		}
	}
	#context: (#TestCtx & {release: "clickstack", namespace: "observability", component: "gateway"}).out
}).output & {
	apiVersion: "opentelemetry.io/v1beta1"
	kind:       "OpenTelemetryCollector"
	metadata: {
		name:      "clickstack-gateway"
		namespace: "observability"
	}
}
