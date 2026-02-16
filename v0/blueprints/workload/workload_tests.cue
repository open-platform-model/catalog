@if(test)

package workload

import (
	schemas "opmodel.dev/schemas@v0"
)

// =============================================================================
// Workload Blueprint Tests
// =============================================================================

// ── StatelessWorkload ────────────────────────────────────────────

// Test: StatelessWorkloadBlueprint definition structure
_testStatelessBlueprintDef: #StatelessWorkloadBlueprint & {
	metadata: {
		apiVersion: "opmodel.dev/blueprints/workload@v0"
		name:       "stateless-workload"
		fqn:        "opmodel.dev/blueprints/workload@v0#StatelessWorkload"
	}
}

// Test: StatelessWorkload component with minimal config
_testStatelessWorkloadMinimal: #StatelessWorkload & {
	metadata: {
		name: "web"
		labels: "core.opmodel.dev/workload-type": "stateless"
	}
	spec: statelessWorkload: {
		container: {
			name:  "web"
			image: "nginx:latest"
		}
	}
}

// Test: StatelessWorkload with full config
_testStatelessWorkloadFull: #StatelessWorkload & {
	metadata: {
		name: "api"
		labels: "core.opmodel.dev/workload-type": "stateless"
	}
	spec: statelessWorkload: {
		container: {
			name:  "api"
			image: "myapi:1.0"
			ports: http: {
				name:       "http"
				targetPort: 8080
			}
			resources: {
				limits: cpu:   "500m"
				requests: cpu: "100m"
			}
		}
		scaling: count: 3
		restartPolicy: "Always"
		updateStrategy: type: "RollingUpdate"
		healthCheck: {
			livenessProbe: httpGet: {
				path: "/healthz"
				port: 8080
			}
		}
	}
}

// ── StatefulWorkload ─────────────────────────────────────────────

// Test: StatefulWorkload with volumes
_testStatefulWorkloadWithVolumes: #StatefulWorkload & {
	metadata: {
		name: "database"
		labels: "core.opmodel.dev/workload-type": "stateful"
	}
	spec: statefulWorkload: {
		container: {
			name:  "postgres"
			image: "postgres:16"
			env: POSTGRES_PASSWORD: {
				name:  "POSTGRES_PASSWORD"
				value: "secret"
			}
		}
		volumes: data: {
			name: "data"
			persistentClaim: {
				size:       "50Gi"
				accessMode: "ReadWriteOnce"
			}
		}
	}
}

// ── DaemonWorkload ───────────────────────────────────────────────

// Test: DaemonWorkload minimal
_testDaemonWorkloadMinimal: #DaemonWorkload & {
	metadata: {
		name: "log-agent"
		labels: "core.opmodel.dev/workload-type": "daemon"
	}
	spec: daemonWorkload: {
		container: {
			name:  "fluentd"
			image: "fluentd:latest"
		}
	}
}

// ── TaskWorkload ─────────────────────────────────────────────────

// Test: TaskWorkload (one-time job)
_testTaskWorkloadMinimal: #TaskWorkload & {
	metadata: {
		name: "migration"
		labels: "core.opmodel.dev/workload-type": "task"
	}
	spec: taskWorkload: {
		container: {
			name:  "migrate"
			image: "flyway:latest"
			command: ["flyway", "migrate"]
		}
		restartPolicy: "Never"
	}
}

// Test: TaskWorkload with job config
_testTaskWorkloadWithJobConfig: #TaskWorkload & {
	metadata: {
		name: "batch-job"
		labels: "core.opmodel.dev/workload-type": "task"
	}
	spec: taskWorkload: {
		container: {
			name:  "processor"
			image: "batch:latest"
			command: ["./process"]
		}
		restartPolicy: "OnFailure"
		jobConfig: {
			completions:  10
			parallelism:  3
			backoffLimit: 3
		}
	}
}

// ── ScheduledTaskWorkload ────────────────────────────────────────

// Test: ScheduledTaskWorkload (cron job)
_testScheduledTaskWorkloadMinimal: #ScheduledTaskWorkload & {
	metadata: {
		name: "nightly-backup"
		labels: "core.opmodel.dev/workload-type": "scheduled-task"
	}
	spec: scheduledTaskWorkload: {
		container: {
			name:  "backup"
			image: "backup-tool:latest"
			command: ["./backup.sh"]
		}
		cronJobConfig: {
			scheduleCron:      "0 2 * * *"
			concurrencyPolicy: "Forbid"
		}
	}
}

// ── Blueprint spec fan-out verification ──────────────────────────
// Verify that the blueprint spec correctly fans out to individual trait/resource specs

_testStatelessSpecFanOut: #StatelessWorkload & {
	metadata: {
		name: "fanout-test"
		labels: "core.opmodel.dev/workload-type": "stateless"
	}
	spec: {
		statelessWorkload: {
			container: {
				name:  "test"
				image: "test:latest"
			}
			scaling: count: 5
		}
		// Verify fan-out: container spec should match the blueprint's container
		container: {
			name:  "test"
			image: "test:latest"
		}
		// Verify fan-out: scaling should match
		scaling: count: 5
	}
}

// ── Schema references are correct ────────────────────────────────

_testBlueprintSchemaRef: {
	// Verify that blueprint spec references the correct schema types
	_s:  schemas.#StatelessWorkloadSchema
	_d:  schemas.#DaemonWorkloadSchema
	_t:  schemas.#TaskWorkloadSchema
	_st: schemas.#ScheduledTaskWorkloadSchema
	_sf: schemas.#StatefulWorkloadSchema
}

// ── StatefulWorkload with all optional traits ────────────────────

_testStatefulWorkloadAllTraits: #StatefulWorkload & {
	metadata: {
		name: "database-full"
		labels: "core.opmodel.dev/workload-type": "stateful"
	}
	spec: statefulWorkload: {
		container: {
			name:  "db"
			image: "postgres:16"
			ports: postgres: {
				name:       "postgres"
				targetPort: 5432
			}
			resources: {
				limits: {
					cpu:    "2000m"
					memory: "4Gi"
				}
				requests: {
					cpu:    "1000m"
					memory: "2Gi"
				}
			}
		}
		volumes: {
			data: {
				name: "data"
				persistentClaim: {
					size:         "100Gi"
					accessMode:   "ReadWriteOnce"
					storageClass: "ssd"
				}
			}
		}
		scaling: count: 3
		healthCheck: {
			livenessProbe: {
				tcpSocket: port: 5432
				initialDelaySeconds: 30
			}
			readinessProbe: {
				exec: command: ["pg_isready", "-U", "postgres"]
			}
		}
	}
}

// ── DaemonWorkload with health checks ────────────────────────────

_testDaemonWorkloadWithHealthChecks: #DaemonWorkload & {
	metadata: {
		name: "node-exporter"
		labels: "core.opmodel.dev/workload-type": "daemon"
	}
	spec: daemonWorkload: {
		container: {
			name:  "exporter"
			image: "node-exporter:latest"
			ports: metrics: {
				name:       "metrics"
				targetPort: 9100
			}
		}
		healthCheck: {
			livenessProbe: httpGet: {
				path: "/metrics"
				port: 9100
			}
		}
	}
}

// ── Multiple sidecar/init containers ──────────────────────────────

_testStatelessWithSidecars: #StatelessWorkload & {
	metadata: {
		name: "app-with-sidecars"
		labels: "core.opmodel.dev/workload-type": "stateless"
	}
	spec: statelessWorkload: {
		container: {
			name:  "app"
			image: "myapp:latest"
		}
		sidecarContainers: [
			{
				name:  "logging"
				image: "fluentd:latest"
			},
			{
				name:  "metrics"
				image: "prometheus-exporter:latest"
			},
		]
		initContainers: [
			{
				name:  "setup"
				image: "busybox:latest"
				command: ["sh", "-c", "echo setup"]
			},
		]
	}
}
