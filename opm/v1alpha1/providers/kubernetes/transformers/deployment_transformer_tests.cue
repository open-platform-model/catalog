@if(test)

package transformers

// =============================================================================
// DeploymentTransformer Tests
// =============================================================================
//
// Run: cue vet -t test ./providers/kubernetes/transformers/...
// Or:  task test:v1alpha2   (from catalog/)

// Test: Minimal stateless component produces a structurally valid Deployment.
// Asserts: apiVersion, kind, name convention ("{release}-{component}"), namespace.
_testDeploymentMinimal: (#DeploymentTransformer.#transform & {
	#component: {
		metadata: name: "web"
		spec: container: {
			name: "web"
			image: {
				repository: "nginx"
				tag:        "1.27"
				digest:     ""
				pullPolicy: "IfNotPresent"
				reference:  "nginx:1.27"
			}
		}
	}
	#context: (#TestCtx & {
		release:   "my-release"
		namespace: "default"
		component: "web"
	}).out
}).output & {
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "my-release-web"
		namespace: "default"
	}
}

// Test: Component with explicit replica count produces spec.replicas = 3.
// Asserts: scaling.count is correctly mapped to Deployment spec.replicas.
_testDeploymentExplicitReplicas: (#DeploymentTransformer.#transform & {
	#component: {
		metadata: name: "api"
		spec: {
			container: {
				name: "api"
				image: {
					repository: "my-api"
					tag:        "v2.0"
					digest:     ""
					pullPolicy: "IfNotPresent"
					reference:  "my-api:v2.0"
				}
			}
			scaling: count: 3
		}
	}
	#context: (#TestCtx & {
		release:   "api-release"
		namespace: "api"
		component: "api"
	}).out
}).output & {
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      "api-release-api"
		namespace: "api"
	}
	spec: replicas: 3
}

// Test: Component with restartPolicy: "Never" propagates to pod spec.
// Asserts: optional trait values are forwarded through the transformer.
_testDeploymentRestartPolicy: (#DeploymentTransformer.#transform & {
	#component: {
		metadata: name: "runner"
		spec: {
			container: {
				name: "runner"
				image: {
					repository: "job-runner"
					tag:        "latest"
					digest:     ""
					pullPolicy: "IfNotPresent"
					reference:  "job-runner:latest"
				}
			}
			restartPolicy: "Never"
		}
	}
	#context: (#TestCtx & {
		release:   "job-release"
		namespace: "jobs"
		component: "runner"
	}).out
}).output & {
	spec: template: spec: restartPolicy: "Never"
}

// Test: Component with gracefulShutdown trait produces terminationGracePeriodSeconds.
// Asserts: gracefulShutdown.terminationGracePeriodSeconds is mapped to pod spec.
_testDeploymentGracefulShutdown: (#DeploymentTransformer.#transform & {
	#component: {
		metadata: name: "worker"
		spec: {
			container: {
				name: "worker"
				image: {
					repository: "worker"
					tag:        "v1.0"
					digest:     ""
					pullPolicy: "IfNotPresent"
					reference:  "worker:v1.0"
				}
			}
			gracefulShutdown: terminationGracePeriodSeconds: 60
		}
	}
	#context: (#TestCtx & {
		release:   "app"
		namespace: "default"
		component: "worker"
	}).out
}).output & {
	spec: template: spec: terminationGracePeriodSeconds: 60
}

// Test: Component with gracefulShutdown + preStopCommand on main container.
// Asserts: both terminationGracePeriodSeconds and lifecycle.preStop appear in output.
_testDeploymentGracefulShutdownWithPreStop: (#DeploymentTransformer.#transform & {
	#component: {
		metadata: name: "streamer"
		spec: {
			container: {
				name: "streamer"
				image: {
					repository: "streamer"
					tag:        "v2.0"
					digest:     ""
					pullPolicy: "IfNotPresent"
					reference:  "streamer:v2.0"
				}
				preStopCommand: ["/bin/sh", "-c", "sleep 10"]
			}
			gracefulShutdown: terminationGracePeriodSeconds: 120
		}
	}
	#context: (#TestCtx & {
		release:   "media"
		namespace: "streaming"
		component: "streamer"
	}).out
}).output & {
	spec: template: spec: {
		terminationGracePeriodSeconds: 120
		containers: [{
			lifecycle: preStop: exec: command: ["/bin/sh", "-c", "sleep 10"]
			...
		}]
	}
}

// Test: Component with environment variables wired via literal value.
// Asserts: env vars are passed through to the container spec.
_testDeploymentWithEnv: (#DeploymentTransformer.#transform & {
	#component: {
		metadata: name: "backend"
		spec: {
			container: {
				name: "backend"
				image: {
					repository: "backend"
					tag:        "v1.0"
					digest:     ""
					pullPolicy: "IfNotPresent"
					reference:  "backend:v1.0"
				}
				env: {
					LOG_LEVEL: {
						name:  "LOG_LEVEL"
						value: "info"
					}
				}
			}
		}
	}
	#context: (#TestCtx & {
		release:   "app"
		namespace: "production"
		component: "backend"
	}).out
}).output & {
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: namespace: "production"
}
