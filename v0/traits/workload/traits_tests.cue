@if(test)

package workload

// =============================================================================
// Workload Traits Tests (remaining traits not covered by individual files)
// =============================================================================

// ── SizingTrait ──────────────────────────────────────────────────

_testSizingTraitDef: #SizingTrait & {
	metadata: {
		apiVersion: "opmodel.dev/traits/workload@v0"
		name:       "sizing"
		fqn:        "opmodel.dev/traits/workload@v0#Sizing"
	}
}

_testSizingComponent: #Sizing & {
	metadata: name: "sizing-test"
	spec: sizing: {
		cpu: {
			request: "100m"
			limit:   "500m"
		}
		memory: {
			request: "128Mi"
			limit:   "512Mi"
		}
	}
}

// ── RestartPolicyTrait ───────────────────────────────────────────

_testRestartPolicyTraitDef: #RestartPolicyTrait & {
	metadata: {
		apiVersion: "opmodel.dev/traits/workload@v0"
		name:       "restart-policy"
		fqn:        "opmodel.dev/traits/workload@v0#RestartPolicy"
	}
}

_testRestartPolicyAlways: #RestartPolicy & {
	metadata: name:      "restart-always"
	spec: restartPolicy: "Always"
}

_testRestartPolicyNever: #RestartPolicy & {
	metadata: name:      "restart-never"
	spec: restartPolicy: "Never"
}

_testRestartPolicyOnFailure: #RestartPolicy & {
	metadata: name:      "restart-onfailure"
	spec: restartPolicy: "OnFailure"
}

// ── UpdateStrategyTrait ──────────────────────────────────────────

_testUpdateStrategyTraitDef: #UpdateStrategyTrait & {
	metadata: {
		apiVersion: "opmodel.dev/traits/workload@v0"
		name:       "update-strategy"
		fqn:        "opmodel.dev/traits/workload@v0#UpdateStrategy"
	}
}

_testUpdateStrategyRolling: #UpdateStrategy & {
	metadata: name: "update-rolling"
	spec: updateStrategy: {
		type: "RollingUpdate"
		rollingUpdate: {
			maxUnavailable: 1
			maxSurge:       1
		}
	}
}

_testUpdateStrategyRecreate: #UpdateStrategy & {
	metadata: name: "update-recreate"
	spec: updateStrategy: type: "Recreate"
}

// ── SidecarContainersTrait ───────────────────────────────────────

_testSidecarContainersComponent: #SidecarContainers & {
	metadata: name: "sidecar-test"
	spec: sidecarContainers: [{
		name:  "envoy"
		image: "envoy:latest"
	}]
}

// ── InitContainersTrait ──────────────────────────────────────────

_testInitContainersComponent: #InitContainers & {
	metadata: name: "init-test"
	spec: initContainers: [{
		name:  "init-db"
		image: "flyway:latest"
		command: ["flyway", "migrate"]
	}]
}

// ── JobConfigTrait ───────────────────────────────────────────────

_testJobConfigTraitDef: #JobConfigTrait & {
	metadata: {
		apiVersion: "opmodel.dev/traits/workload@v0"
		name:       "job-config"
		fqn:        "opmodel.dev/traits/workload@v0#JobConfig"
	}
}

_testJobConfigComponent: #JobConfig & {
	metadata: name: "job-test"
	spec: jobConfig: {
		completions:  3
		parallelism:  2
		backoffLimit: 3
	}
}

// ── CronJobConfigTrait ───────────────────────────────────────────

_testCronJobConfigTraitDef: #CronJobConfigTrait & {
	metadata: {
		apiVersion: "opmodel.dev/traits/workload@v0"
		name:       "cron-job-config"
		fqn:        "opmodel.dev/traits/workload@v0#CronJobConfig"
	}
}

_testCronJobConfigComponent: #CronJobConfig & {
	metadata: name: "cronjob-test"
	spec: cronJobConfig: {
		scheduleCron:      "0 2 * * *"
		concurrencyPolicy: "Forbid"
	}
}

// ── DisruptionBudgetTrait ────────────────────────────────────────

_testDisruptionBudgetMin: #DisruptionBudget & {
	metadata: name: "pdb-min"
	spec: disruptionBudget: minAvailable: 2
}

_testDisruptionBudgetMax: #DisruptionBudget & {
	metadata: name: "pdb-max"
	spec: disruptionBudget: maxUnavailable: "25%"
}

// ── GracefulShutdownTrait ────────────────────────────────────────

_testGracefulShutdownComponent: #GracefulShutdown & {
	metadata: name: "graceful-test"
	spec: gracefulShutdown: {
		terminationGracePeriodSeconds: 60
		preStopCommand: ["nginx", "-s", "quit"]
	}
}

// ── PlacementTrait ───────────────────────────────────────────────

_testPlacementComponent: #Placement & {
	metadata: name: "placement-test"
	spec: placement: {
		spreadAcross: "zones"
		requirements: {
			"node.kubernetes.io/instance-type": "m5.xlarge"
		}
	}
}

// =============================================================================
// Negative Tests
// Negative tests moved to testdata/*.yaml files

// Test default value for GracefulShutdown terminationGracePeriod
_testGracefulShutdownDefaults: #GracefulShutdown & {
	metadata: name: "graceful-default"
	spec: gracefulShutdown: {
		preStopCommand: ["sh", "-c", "sleep 5"]
	}
}
