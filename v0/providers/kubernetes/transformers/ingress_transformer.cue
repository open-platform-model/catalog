package transformers

import (
	core "opmodel.dev/core@v0"
	network_traits "opmodel.dev/traits/network@v0"
)

// IngressTransformer converts HttpRoute trait to Kubernetes Ingress
#IngressTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "opmodel.dev/providers/kubernetes/transformers@v0"
		name:        "ingress-transformer"
		description: "Converts HttpRoute trait to Kubernetes Ingress"

		labels: {
			"core.opmodel.dev/trait-type":    "network"
			"core.opmodel.dev/resource-type": "ingress"
		}
	}

	requiredLabels: {}

	requiredResources: {}
	optionalResources: {}

	// Required traits - HttpRoute MUST be present
	requiredTraits: {
		"opmodel.dev/traits/network@v0#HttpRoute": network_traits.#HttpRouteTrait
	}

	optionalTraits: {}

	#transform: {
		#component: _
		#context:   core.#TransformerContext

		_httpRoute:   #component.spec.httpRoute
		_serviceName: #component.metadata.name

		// Build paths from all rules
		_allPaths: [
			for rule in _httpRoute.rules {
				if rule.matches != _|_ {
					for match in rule.matches {
						if match.path != _|_ {
							path:     match.path.value
							pathType: match.path.type
							backend: {
								service: {
									name: _serviceName
									port: number: rule.backendPort
								}
							}
						}
					}
				}
				if rule.matches == _|_ {
					path:     "/"
					pathType: "Prefix"
					backend: {
						service: {
							name: _serviceName
							port: number: rule.backendPort
						}
					}
				}
			},
		]

		output: {
			apiVersion: "networking.k8s.io/v1"
			kind:       "Ingress"
			metadata: {
				name:      #component.metadata.name
				namespace: #context.namespace
				labels:    #context.labels
			}
			spec: {
				if _httpRoute.ingressClassName != _|_ {
					ingressClassName: _httpRoute.ingressClassName
				}

				if _httpRoute.hostnames != _|_ {
					rules: [
						for hostname in _httpRoute.hostnames {
							host: hostname
							http: paths: _allPaths
						},
					]
				}

				if _httpRoute.hostnames == _|_ {
					rules: [{
						http: paths: _allPaths
					}]
				}

				if _httpRoute.tls != _|_ if _httpRoute.tls.certificateRef != _|_ {
					tls: [{
						secretName: _httpRoute.tls.certificateRef.name
						if _httpRoute.hostnames != _|_ {
							hosts: _httpRoute.hostnames
						}
					}]
				}
			}
		}
	}
}

_testIngressTransformer: #IngressTransformer.#transform & {
	#component: _testIngressComponent
	#context:   _testContext
}
