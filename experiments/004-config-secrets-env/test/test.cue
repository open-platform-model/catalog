// End-to-end test harness for config/secrets/env flow.
//
// Tests the full pipeline WITHOUT the CLI by manually wiring:
//   concrete component → transformer #transform → K8s output
//
// Run:
//   cue eval ./test/           (from experiments/004-config-secrets-env/)
//   cue eval -e deployment ./test/   (just the Deployment)
//   cue eval -e secrets ./test/      (just the Secrets/ExternalSecrets)
//   cue eval -e configmaps ./test/   (just the ConfigMaps)
//
// Verification points:
//   1. deployment.output.spec.template.spec.containers[0].env
//      → value, secretKeyRef, fieldRef, resourceFieldRef dispatch
//   2. deployment.output.spec.template.spec.containers[0].envFrom
//      → bulk secret injection
//   3. deployment.output.spec.template.spec.containers[0].volumeMounts
//      → clean {name, mountPath} only (no embedded volume source data)
//   4. deployment.output.spec.template.spec.volumes
//      → configMap/secret with correct computed names, emptyDir
//   5. secrets.output
//      → K8s Secret for literals, ExternalSecret for ESO, nothing for K8sRef
//   6. configmaps.output
//      → immutable ConfigMap gets hash suffix, mutable does not
package test

import (
	core "opmodel.dev/core@v1"
	schemas "opmodel.dev/schemas@v1"
	transformers "opmodel.dev/providers/kubernetes/transformers@v1"
)

/////////////////////////////////////////////////////////////////
//// Test Data: Secrets and ConfigMaps
/////////////////////////////////////////////////////////////////

// db-creds: mixed variants (literal + k8sRef + esoRef)
_dbCredsSecret: schemas.#SecretSchema & {
	name: "db-creds"
	data: {
		password: schemas.#SecretLiteral & {
			$secretName: "db-creds"
			$dataKey:    "password"
			value:       "s3cret!"
		}
		host: schemas.#SecretK8sRef & {
			$secretName: "db-creds"
			$dataKey:    "host"
			secretName:  "cloud-sql-credentials"
			remoteKey:   "hostname"
		}
		"api-key": schemas.#SecretEsoRef & {
			$secretName:  "db-creds"
			$dataKey:     "api-key"
			externalPath: "prod/db/api-key"
			remoteKey:    "value"
		}
	}
}

// tls: pure K8sRef (should produce NO output from secret transformer)
_tlsSecret: schemas.#SecretSchema & {
	name: "tls"
	type: "kubernetes.io/tls"
	data: {
		"tls.crt": schemas.#SecretK8sRef & {
			$secretName: "tls"
			$dataKey:    "tls.crt"
			secretName:  "my-tls-cert"
			remoteKey:   "tls.crt"
		}
		"tls.key": schemas.#SecretK8sRef & {
			$secretName: "tls"
			$dataKey:    "tls.key"
			secretName:  "my-tls-cert"
			remoteKey:   "tls.key"
		}
	}
}

// app-config: immutable (should get content-hash suffix)
_appConfigCM: schemas.#ConfigMapSchema & {
	name:      "app-config"
	immutable: true
	data: {
		"app.conf":      "log_level=info\nmax_connections=100"
		"features.json": "{\"dark_mode\": true}"
		"test":          "test"
	}
}

// nginx-conf: mutable (should keep plain name)
_nginxConfCM: schemas.#ConfigMapSchema & {
	name: "nginx-conf"
	data: {
		"nginx.conf": "server { listen 80; }"
	}
}

/////////////////////////////////////////////////////////////////
//// Test Data: Component (bypasses Module/Release pipeline)
/////////////////////////////////////////////////////////////////

_component: {
	metadata: {
		name: "web"
		labels: {
			"core.opmodel.dev/workload-type": "stateless"
		}
	}

	spec: {
		// --- Secrets ---
		secrets: {
			"db-creds": _dbCredsSecret
			tls:        _tlsSecret
		}

		// --- ConfigMaps ---
		configMaps: {
			"app-config": _appConfigCM
			"nginx-conf": _nginxConfCM
		}

		// --- Container ---
		container: schemas.#ContainerSchema & {
			name: "app"
			image: {
				repository: "myorg/myapp"
				tag:        "v1.2.3"
				digest:     ""
			}
			ports: http: {
				name:       "http"
				targetPort: 8080
				protocol:   "TCP"
			}

			// Env: all 4 dispatch types
			env: {
				// 1. Literal value
				LOG_LEVEL: {
					name:  "LOG_LEVEL"
					value: "info"
				}
				// 2. Secret reference (literal variant → secretKeyRef using $secretName/$dataKey)
				DB_PASSWORD: {
					name: "DB_PASSWORD"
					from: _dbCredsSecret.data.password
				}
				// 3. Secret reference (k8sRef variant → secretKeyRef using secretName/remoteKey)
				DB_HOST: {
					name: "DB_HOST"
					from: _dbCredsSecret.data.host
				}
				// 4. Downward API fieldRef
				POD_NAME: {
					name: "POD_NAME"
					fieldRef: fieldPath: "metadata.name"
				}
				// 5. Resource fieldRef
				CPU_LIMIT: {
					name: "CPU_LIMIT"
					resourceFieldRef: {
						resource: "limits.cpu"
						divisor:  "1m"
					}
				}
			}

			// envFrom: bulk injection from a secret
			envFrom: [{
				secretRef: name: "db-creds"
				prefix: "DB_"
			}]

			resources: {
				requests: {cpu: "250m", memory: "128Mi"}
				limits: {cpu: "500m", memory: "256Mi"}
			}

			// Volume mounts: configMap + secret + emptyDir
			// These embed the full #VolumeSchema (CUE reference),
			// but the container helper must strip source data from K8s output.
			volumeMounts: {
				"app-config": schemas.#VolumeMountSchema & {
					mountPath: "/etc/app"
					readOnly:  true
				} & volumes["app-config"]
				"db-secrets": schemas.#VolumeMountSchema & {
					mountPath: "/etc/secrets/db"
					readOnly:  true
				} & volumes["db-secrets"]
				"tmp": schemas.#VolumeMountSchema & {
					mountPath: "/tmp"
				} & volumes["tmp"]
			}
		}

		// --- Volumes (same references as volumeMounts, independent transformer reads) ---
		volumes: {
			"app-config": schemas.#VolumeSchema & {
				name:      "app-config"
				configMap: _appConfigCM
			}
			"db-secrets": schemas.#VolumeSchema & {
				name:   "db-secrets"
				secret: _dbCredsSecret
			}
			"tmp": schemas.#VolumeSchema & {
				name: "tmp"
				emptyDir: {}
			}
		}
	}
}

/////////////////////////////////////////////////////////////////
//// Transformer Context (minimal stub)
/////////////////////////////////////////////////////////////////

_ctx: core.#TransformerContext & {
	#moduleReleaseMetadata: {
		name:      "myapp"
		namespace: "default"
		fqn:       "test/myapp"
		version:   "1.0.0"
		uuid:      "00000000-0000-0000-0000-000000000000"
	}
	#componentMetadata: {
		name: "web"
		labels: {
			"core.opmodel.dev/workload-type": "stateless"
		}
	}
	name:      "myapp"
	namespace: "default"
}

/////////////////////////////////////////////////////////////////
//// Transformer Invocations
/////////////////////////////////////////////////////////////////

// K8s Deployment — validates env dispatch, volumeMounts, volumes
deployment: (transformers.#DeploymentTransformer.#transform & {
	#component: _component
	#context:   _ctx
})

// K8s Secrets + ExternalSecrets — validates variant dispatch
secrets: (transformers.#SecretTransformer.#transform & {
	#component: _component
	#context:   _ctx
})

// K8s ConfigMaps — validates immutable naming
configmaps: (transformers.#ConfigMapTransformer.#transform & {
	#component: _component
	#context:   _ctx
})
