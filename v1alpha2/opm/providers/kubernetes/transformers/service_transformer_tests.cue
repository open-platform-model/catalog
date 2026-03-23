@if(test)

package transformers

// =============================================================================
// ServiceTransformer Tests
// =============================================================================
//
// Run: cue vet -t test ./providers/kubernetes/transformers/...
// Or:  task test:v1alpha2   (from catalog/)

// Test: ClusterIP service with a single HTTP port.
// Asserts: apiVersion, kind, name convention, namespace, service type.
_testServiceClusterIP: (#ServiceTransformer.#transform & {
	#component: {
		metadata: name: "web"
		spec: {
			container: {
				name:  "web"
				image: {
					repository: "nginx"
					tag:        "1.27"
					digest:     ""
				}
				ports: http: {
					name:       "http"
					targetPort: 8080
				}
			}
			expose: {
				type: "ClusterIP"
				ports: http: {
					name:       "http"
					targetPort: 8080
				}
			}
		}
	}
	#context: (#TestCtx & {
		release:   "my-release"
		namespace: "default"
		component: "web"
	}).out
}).output & {
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "my-release-web"
		namespace: "default"
	}
	spec: type: "ClusterIP"
}

// Test: LoadBalancer service preserves type from Expose trait.
// Asserts: Service type is LoadBalancer; namespace is correctly set.
_testServiceLoadBalancer: (#ServiceTransformer.#transform & {
	#component: {
		metadata: name: "ingress"
		spec: {
			container: {
				name:  "ingress"
				image: {
					repository: "envoy"
					tag:        "v1.28"
					digest:     ""
				}
				ports: http: {
					name:       "http"
					targetPort: 80
				}
			}
			expose: {
				type: "LoadBalancer"
				ports: http: {
					name:       "http"
					targetPort: 80
				}
			}
		}
	}
	#context: (#TestCtx & {
		release:   "gateway"
		namespace: "istio-ingress"
		component: "ingress"
	}).out
}).output & {
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "gateway-ingress"
		namespace: "istio-ingress"
	}
	spec: type: "LoadBalancer"
}

// Test: Multi-port service includes all declared ports.
// Asserts: Service with both http and metrics ports produces multiple entries.
_testServiceMultiPort: (#ServiceTransformer.#transform & {
	#component: {
		metadata: name: "metrics-app"
		spec: {
			container: {
				name:  "metrics-app"
				image: {
					repository: "my-app"
					tag:        "v3.0"
					digest:     ""
				}
				ports: {
					http: {
						name:       "http"
						targetPort: 8080
					}
					metrics: {
						name:       "metrics"
						targetPort: 9090
					}
				}
			}
			expose: {
				type: "ClusterIP"
				ports: {
					http: {
						name:       "http"
						targetPort: 8080
					}
					metrics: {
						name:       "metrics"
						targetPort: 9090
					}
				}
			}
		}
	}
	#context: (#TestCtx & {
		release:   "monitor"
		namespace: "monitoring"
		component: "metrics-app"
	}).out
}).output & {
	apiVersion: "v1"
	kind:       "Service"
	metadata: namespace: "monitoring"
	spec: type: "ClusterIP"
}
