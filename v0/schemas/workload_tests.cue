@if(test)

package schemas

// =============================================================================
// Workload Schema Tests
// =============================================================================

// ── ContainerSchema ──────────────────────────────────────────────

// Test: minimal valid container
_testContainerMinimal: #ContainerSchema & {
	name:  "web"
	image: "nginx:latest"
}

// Test: container with all optional fields
_testContainerFull: #ContainerSchema & {
	name:            "web"
	image:           "nginx:1.25"
	imagePullPolicy: "Always"
	ports: {
		http: {
			name:       "http"
			targetPort: 80
		}
	}
	env: {
		ENVIRONMENT: {
			name:  "ENVIRONMENT"
			value: "production"
		}
	}
	command: ["nginx", "-g", "daemon off;"]
	args: ["--config", "/etc/nginx/nginx.conf"]
	resources: {
		limits: {
			cpu:    "500m"
			memory: "256Mi"
		}
		requests: {
			cpu:    "100m"
			memory: "128Mi"
		}
	}
}

// Test: container with volume mounts
_testContainerWithMounts: #ContainerSchema & {
	name:  "app"
	image: "myapp:latest"
	volumeMounts: {
		data: {
			name:      "data"
			mountPath: "/data"
			readOnly:  false
		}
		config: {
			name:      "config"
			mountPath: "/etc/config"
			readOnly:  true
			subPath:   "app.conf"
		}
	}
}

// Test: default imagePullPolicy is "IfNotPresent"
_testContainerDefaultPullPolicy: #ContainerSchema & {
	name:            "web"
	image:           "nginx:latest"
	imagePullPolicy: "IfNotPresent"
}

// ── ScalingSchema ────────────────────────────────────────────────

// Test: default count is 1
_testScalingDefault: #ScalingSchema & {
	count: 1
}

// Test: max count boundary
_testScalingMax: #ScalingSchema & {
	count: 1000
}

// Test: autoscaling config
_testScalingAuto: #ScalingSchema & {
	count: 2
	auto: {
		min: 1
		max: 10
		metrics: [{
			type: "cpu"
			target: {
				averageUtilization: 80
			}
		}]
	}
}

// Test: autoscaling with custom metric
_testScalingCustomMetric: #ScalingSchema & {
	count: 3
	auto: {
		min: 2
		max: 20
		metrics: [
			{
				type: "cpu"
				target: averageUtilization: 70
			},
			{
				type:       "custom"
				metricName: "requests_per_second"
				target: averageValue: "100"
			},
		]
		behavior: {
			scaleUp: stabilizationWindowSeconds:   60
			scaleDown: stabilizationWindowSeconds: 300
		}
	}
}

// ── SizingSchema ─────────────────────────────────────────────────

_testSizingFull: #SizingSchema & {
	cpu: {
		request: "100m"
		limit:   "500m"
	}
	memory: {
		request: "128Mi"
		limit:   "512Mi"
	}
}

_testSizingNumbers: #SizingSchema & {
	cpu: {
		request: 0.5
		limit:   2
	}
	memory: {
		request: 0.5
		limit:   4
	}
}

_testSizingCPUOnly: #SizingSchema & {
	cpu: {
		request: "500m"
		limit:   "2000m"
	}
}

_testSizingMemoryOnly: #SizingSchema & {
	memory: {
		request: "256Mi"
		limit:   "1Gi"
	}
}

_testSizingMixed: #SizingSchema & {
	cpu: {
		request: 2
		limit:   "8000m"
	}
	memory: {
		request: "512Mi"
		limit:   4
	}
}

_testSizingLargeValues: #SizingSchema & {
	cpu: {
		request: 16
		limit:   64
	}
	memory: {
		request: 32
		limit:   128
	}
}

_testSizingSmallFractions: #SizingSchema & {
	cpu: {
		request: 0.1
		limit:   0.5
	}
	memory: {
		request: 0.125
		limit:   0.25
	}
}

// ── HealthCheckSchema ────────────────────────────────────────────

_testHealthCheckHTTP: #HealthCheckSchema & {
	livenessProbe: {
		httpGet: {
			path: "/healthz"
			port: 8080
		}
		initialDelaySeconds: 10
		periodSeconds:       15
	}
	readinessProbe: {
		httpGet: {
			path: "/ready"
			port: 8080
		}
	}
}

_testHealthCheckExec: #HealthCheckSchema & {
	livenessProbe: {
		exec: command: ["pg_isready", "-U", "postgres"]
	}
	readinessProbe: {
		tcpSocket: port: 5432
	}
}

// ── UpdateStrategySchema ─────────────────────────────────────────

_testUpdateStrategyRolling: #UpdateStrategySchema & {
	type: "RollingUpdate"
	rollingUpdate: {
		maxUnavailable: 1
		maxSurge:       1
	}
}

_testUpdateStrategyRecreate: #UpdateStrategySchema & {
	type: "Recreate"
}

// ── JobConfigSchema ──────────────────────────────────────────────

_testJobConfig: #JobConfigSchema & {
	completions:             3
	parallelism:             2
	backoffLimit:            3
	activeDeadlineSeconds:   600
	ttlSecondsAfterFinished: 300
}

// ── CronJobConfigSchema ──────────────────────────────────────────

_testCronJobConfig: #CronJobConfigSchema & {
	scheduleCron:               "0 * * * *"
	concurrencyPolicy:          "Forbid"
	successfulJobsHistoryLimit: 5
	failedJobsHistoryLimit:     3
}

// ── Workload Composite Schemas ───────────────────────────────────

_testStatelessWorkload: #StatelessWorkloadSchema & {
	container: {
		name:  "web"
		image: "nginx:latest"
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

_testStatefulWorkload: #StatefulWorkloadSchema & {
	container: {
		name:  "db"
		image: "postgres:16"
	}
	volumes: {
		data: {
			name: "data"
			persistentClaim: {
				size:       "10Gi"
				accessMode: "ReadWriteOnce"
			}
		}
	}
}

_testDaemonWorkload: #DaemonWorkloadSchema & {
	container: {
		name:  "fluentd"
		image: "fluentd:latest"
	}
}

_testTaskWorkload: #TaskWorkloadSchema & {
	container: {
		name:  "migration"
		image: "myapp:latest"
		command: ["./migrate"]
	}
	restartPolicy: "Never"
	jobConfig: {
		backoffLimit:          3
		activeDeadlineSeconds: 300
	}
}

_testScheduledTaskWorkload: #ScheduledTaskWorkloadSchema & {
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

// ── DisruptionBudgetSchema ───────────────────────────────────────

_testDisruptionBudgetMin: #DisruptionBudgetSchema & {
	minAvailable: 1
}

_testDisruptionBudgetMax: #DisruptionBudgetSchema & {
	maxUnavailable: "25%"
}

// ── GracefulShutdownSchema ───────────────────────────────────────

_testGracefulShutdown: #GracefulShutdownSchema & {
	terminationGracePeriodSeconds: 60
	preStopCommand: ["nginx", "-s", "quit"]
}

// ── PlacementSchema ──────────────────────────────────────────────

_testPlacement: #PlacementSchema & {
	spreadAcross: "zones"
	requirements: {
		"node.kubernetes.io/instance-type": "m5.xlarge"
	}
}

// ── EnvVarSchema (previously untested) ───────────────────────────

_testEnvVarMinimal: #EnvVarSchema & {
	name:  "ENV_VAR"
	value: "value"
}

// ── ResourceRequirementsSchema (previously untested) ─────────────

_testResourceRequirements: #ResourceRequirementsSchema & {
	limits: {
		cpu:    "1000m"
		memory: "1Gi"
	}
	requests: {
		cpu:    "500m"
		memory: "512Mi"
	}
}

_testResourceRequirementsLimitsOnly: #ResourceRequirementsSchema & {
	limits: {
		memory: "256Mi"
	}
}

_testResourceRequirementsNumbers: #ResourceRequirementsSchema & {
	limits: {
		cpu:    8
		memory: 4
	}
	requests: {
		cpu:    2
		memory: 0.5
	}
}

_testResourceRequirementsRequestsOnly: #ResourceRequirementsSchema & {
	requests: {
		cpu:    "500m"
		memory: "256Mi"
	}
}

_testResourceRequirementsCPUOnly: #ResourceRequirementsSchema & {
	limits: cpu:   "2000m"
	requests: cpu: "500m"
}

_testResourceRequirementsMixed: #ResourceRequirementsSchema & {
	limits: {
		cpu:    8
		memory: "4Gi"
	}
	requests: {
		cpu:    "500m"
		memory: 0.5
	}
}

_testResourceRequirementsEmpty: #ResourceRequirementsSchema & {}

// ── RestartPolicySchema (previously untested) ────────────────────

_testRestartPolicyAlways:    #RestartPolicySchema & "Always"
_testRestartPolicyOnFailure: #RestartPolicySchema & "OnFailure"
_testRestartPolicyNever:     #RestartPolicySchema & "Never"

// =============================================================================
// Negative Tests
// =============================================================================

// Negative tests moved to testdata/*.yaml files
