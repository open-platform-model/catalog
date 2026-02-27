@if(test)

package schemas

import (
	tst "experiments.dev/test-framework/testkit"
)

#tests: tst.#Tests & {

	// =========================================================================
	// #ContainerSchema
	// =========================================================================

	"#ContainerSchema": [

		// ── Positive ──
		{
			name:       "minimal"
			definition: #ContainerSchema
			input: {
				name:  "web"
				image: "nginx:latest"
			}
			assert: valid: true
		},
		{
			name:       "full"
			definition: #ContainerSchema
			input: {
				name:            "web"
				image:           "nginx:1.25"
				imagePullPolicy: "Always"
				ports: http: {
					name:       "http"
					targetPort: 80
				}
				env: ENVIRONMENT: {
					name:  "ENVIRONMENT"
					value: "production"
				}
				command: ["nginx", "-g", "daemon off;"]
				args: ["--config", "/etc/nginx/nginx.conf"]
				resources: {
					cpu: {request: "100m", limit: "500m"}
					memory: {request: "128Mi", limit: "256Mi"}
				}
			}
			assert: valid: true
		},
		{
			name:       "with volume mounts"
			definition: #ContainerSchema
			input: {
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
			assert: valid: true
		},
		{
			name:       "with probes"
			definition: #ContainerSchema
			input: {
				name:  "sidecar"
				image: "busybox:latest"
				startupProbe: {
					exec: command: ["/bin/sh", "-c", "test -f /tmp/ready"]
					periodSeconds:    5
					failureThreshold: 12
				}
				livenessProbe: {
					httpGet: {
						path: "/healthz"
						port: 8080
					}
					periodSeconds:    10
					timeoutSeconds:   3
					failureThreshold: 3
				}
				readinessProbe: {
					tcpSocket: port: 8080
					periodSeconds:    5
					failureThreshold: 3
				}
			}
			assert: valid: true
		},

		// ── Negative ──
		{
			name:       "missing name"
			definition: #ContainerSchema
			input: image:  "nginx:latest"
			assert: valid: false
		},
		{
			name:       "missing image"
			definition: #ContainerSchema
			input: name:   "web"
			assert: valid: false
		},
		{
			name:       "bad pull policy"
			definition: #ContainerSchema
			input: {
				name:            "web"
				image:           "nginx:latest"
				imagePullPolicy: "Sometimes"
			}
			assert: valid: false
		},
	]

	// =========================================================================
	// #ScalingSchema
	// =========================================================================

	"#ScalingSchema": [

		// ── Positive ──
		{
			name:       "default count"
			definition: #ScalingSchema
			input: count:  1
			assert: valid: true
		},
		{
			name:       "max count"
			definition: #ScalingSchema
			input: count:  1000
			assert: valid: true
		},
		{
			name:       "autoscaling"
			definition: #ScalingSchema
			input: {
				count: 2
				auto: {
					min: 1
					max: 10
					metrics: [{
						type: "cpu"
						target: averageUtilization: 80
					}]
				}
			}
			assert: valid: true
		},
		{
			name:       "autoscaling custom metric"
			definition: #ScalingSchema
			input: {
				count: 3
				auto: {
					min: 2
					max: 20
					metrics: [
						{type: "cpu", target: averageUtilization: 70},
						{type: "custom", metricName: "requests_per_second", target: averageValue: "100"},
					]
					behavior: {
						scaleUp: stabilizationWindowSeconds:   60
						scaleDown: stabilizationWindowSeconds: 300
					}
				}
			}
			assert: valid: true
		},

		// ── Negative ──
		{
			name:       "zero count"
			definition: #ScalingSchema
			input: count:  0
			assert: valid: false
		},
		{
			name:       "negative count"
			definition: #ScalingSchema
			input: count:  -5
			assert: valid: false
		},
		{
			name:       "over max count"
			definition: #ScalingSchema
			input: count:  1001
			assert: valid: false
		},
		{
			name:       "auto empty metrics"
			definition: #ScalingSchema
			input: {
				count: 1
				auto: {
					min: 1
					max: 10
					metrics: []
				}
			}
			assert: valid: false
		},
	]

	// =========================================================================
	// #HealthCheckSchema
	// =========================================================================

	"#HealthCheckSchema": [

		// ── Positive ──
		{
			name:       "HTTP probes"
			definition: #HealthCheckSchema
			input: {
				livenessProbe: {
					httpGet: {path: "/healthz", port: 8080}
					initialDelaySeconds: 10
					periodSeconds:       15
				}
				readinessProbe: httpGet: {path: "/ready", port: 8080}
			}
			assert: valid: true
		},
		{
			name:       "exec and tcp probes"
			definition: #HealthCheckSchema
			input: {
				livenessProbe: exec: command: ["pg_isready", "-U", "postgres"]
				readinessProbe: tcpSocket: port: 5432
			}
			assert: valid: true
		},
		{
			name:       "startup probe only"
			definition: #HealthCheckSchema
			input: startupProbe: {
				exec: command: ["mc-health"]
				periodSeconds:    10
				failureThreshold: 30
				timeoutSeconds:   5
			}
			assert: valid: true
		},

		// ── Negative ──
		{
			name:       "bad port zero"
			definition: #HealthCheckSchema
			input: livenessProbe: httpGet: {path: "/healthz", port: 0}
			assert: valid: false
		},
		{
			name:       "port over max"
			definition: #HealthCheckSchema
			input: livenessProbe: httpGet: {path: "/", port: 65536}
			assert: valid: false
		},
	]

	// =========================================================================
	// #UpdateStrategySchema
	// =========================================================================

	"#UpdateStrategySchema": [

		// ── Positive ──
		{
			name:       "rolling update"
			definition: #UpdateStrategySchema
			input: {
				type: "RollingUpdate"
				rollingUpdate: {
					maxUnavailable: 1
					maxSurge:       1
				}
			}
			assert: valid: true
		},
		{
			name:       "recreate"
			definition: #UpdateStrategySchema
			input: type:   "Recreate"
			assert: valid: true
		},

		// ── Negative ──
		{
			name:       "bad type"
			definition: #UpdateStrategySchema
			input: type:   "InvalidStrategy"
			assert: valid: false
		},
	]

	// =========================================================================
	// #JobConfigSchema
	// =========================================================================

	"#JobConfigSchema": [
		{
			name:       "full config"
			definition: #JobConfigSchema
			input: {
				completions:             3
				parallelism:             2
				backoffLimit:            3
				activeDeadlineSeconds:   600
				ttlSecondsAfterFinished: 300
			}
			assert: valid: true
		},
	]

	// =========================================================================
	// #CronJobConfigSchema
	// =========================================================================

	"#CronJobConfigSchema": [
		{
			name:       "full config"
			definition: #CronJobConfigSchema
			input: {
				scheduleCron:               "0 * * * *"
				concurrencyPolicy:          "Forbid"
				successfulJobsHistoryLimit: 5
				failedJobsHistoryLimit:     3
			}
			assert: valid: true
		},
	]

	// =========================================================================
	// #StatelessWorkloadSchema
	// =========================================================================

	"#StatelessWorkloadSchema": [
		{
			name:       "full"
			definition: #StatelessWorkloadSchema
			input: {
				container: {
					name:  "web"
					image: "nginx:latest"
				}
				scaling: count: 3
				restartPolicy: "Always"
				updateStrategy: type: "RollingUpdate"
				healthCheck: livenessProbe: httpGet: {
					path: "/healthz"
					port: 8080
				}
			}
			assert: valid: true
		},
	]

	// =========================================================================
	// #StatefulWorkloadSchema
	// =========================================================================

	"#StatefulWorkloadSchema": [
		{
			name:       "with volumes"
			definition: #StatefulWorkloadSchema
			input: {
				container: {
					name:  "db"
					image: "postgres:16"
				}
				volumes: data: {
					name: "data"
					persistentClaim: {
						size:       "10Gi"
						accessMode: "ReadWriteOnce"
					}
				}
			}
			assert: valid: true
		},
	]

	// =========================================================================
	// #DaemonWorkloadSchema
	// =========================================================================

	"#DaemonWorkloadSchema": [
		{
			name:       "basic"
			definition: #DaemonWorkloadSchema
			input: container: {
				name:  "fluentd"
				image: "fluentd:latest"
			}
			assert: valid: true
		},
	]

	// =========================================================================
	// #TaskWorkloadSchema
	// =========================================================================

	"#TaskWorkloadSchema": [

		// ── Positive ──
		{
			name:       "with job config"
			definition: #TaskWorkloadSchema
			input: {
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
			assert: valid: true
		},

		// ── Negative ──
		{
			name:       "bad restart policy Always"
			definition: #TaskWorkloadSchema
			input: {
				container: {
					name:  "task"
					image: "app:latest"
				}
				restartPolicy: "Always"
			}
			assert: valid: false
		},
	]

	// =========================================================================
	// #ScheduledTaskWorkloadSchema
	// =========================================================================

	"#ScheduledTaskWorkloadSchema": [

		// ── Positive ──
		{
			name:       "with cron config"
			definition: #ScheduledTaskWorkloadSchema
			input: {
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
			assert: valid: true
		},

		// ── Negative ──
		{
			name:       "missing cronJobConfig"
			definition: #ScheduledTaskWorkloadSchema
			input: container: {
				name:  "backup"
				image: "backup:latest"
			}
			assert: valid: false
		},
	]

	// =========================================================================
	// #DisruptionBudgetSchema
	// =========================================================================

	"#DisruptionBudgetSchema": [
		{
			name:       "minAvailable"
			definition: #DisruptionBudgetSchema
			input: minAvailable: 1
			assert: valid:       true
		},
		{
			name:       "maxUnavailable percentage"
			definition: #DisruptionBudgetSchema
			input: maxUnavailable: "25%"
			assert: valid:         true
		},
	]

	// =========================================================================
	// #GracefulShutdownSchema
	// =========================================================================

	"#GracefulShutdownSchema": [
		{
			name:       "full"
			definition: #GracefulShutdownSchema
			input: {
				terminationGracePeriodSeconds: 60
				preStopCommand: ["nginx", "-s", "quit"]
			}
			assert: valid: true
		},
	]

	// =========================================================================
	// #PlacementSchema
	// =========================================================================

	"#PlacementSchema": [
		{
			name:       "with spread and requirements"
			definition: #PlacementSchema
			input: {
				spreadAcross: "zones"
				requirements: "node.kubernetes.io/instance-type": "m5.xlarge"
			}
			assert: valid: true
		},
	]

	// =========================================================================
	// #EnvVarSchema
	// =========================================================================

	"#EnvVarSchema": [
		{
			name:       "minimal"
			definition: #EnvVarSchema
			input: {
				name:  "ENV_VAR"
				value: "value"
			}
			assert: valid: true
		},
		{
			name:       "database URL"
			definition: #EnvVarSchema
			input: {
				name:  "DATABASE_URL"
				value: "postgres://localhost:5432/mydb"
			}
			assert: valid: true
		},
	]

	// =========================================================================
	// #RestartPolicySchema
	// =========================================================================

	"#RestartPolicySchema": [
		{name: "Always", definition: #RestartPolicySchema, input: "Always", assert: valid: true},
		{name: "OnFailure", definition: #RestartPolicySchema, input: "OnFailure", assert: valid: true},
		{name: "Never", definition: #RestartPolicySchema, input: "Never", assert: valid: true},
	]

	// =========================================================================
	// #AutoscalingSpec
	// =========================================================================

	"#AutoscalingSpec": [
		{
			name:       "valid CPU autoscaling"
			definition: #AutoscalingSpec
			input: {
				min: 1
				max: 10
				metrics: [{
					type: "cpu"
					target: averageUtilization: 80
				}]
			}
			assert: valid: true
		},
	]

	// =========================================================================
	// #MetricSpec
	// =========================================================================

	"#MetricSpec": [
		{
			name:       "custom metric missing name"
			definition: #MetricSpec
			input: {
				type: "custom"
				target: averageValue: "100"
			}
			assert: valid: false
		},
	]
}
