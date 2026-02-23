package schemas

/////////////////////////////////////////////////////////////////
//// Container Schemas
/////////////////////////////////////////////////////////////////

// Probe specification used by liveness, readiness, and startup probes.
// Valid for sidecar containers: all three probe types are supported.
// Valid for init containers: only startupProbe is honoured by Kubernetes
// (traditional init containers run to completion; native sidecar init containers
// with restartPolicy: Always support all three probes, requires K8s >= 1.28).
#ProbeSchema: {
	httpGet?: {
		path!: string
		port!: uint & >0 & <65536
	}
	exec?: {
		command!: [...string]
	}
	tcpSocket?: {
		port!: uint & >0 & <65536
	}
	initialDelaySeconds?: uint | *0
	periodSeconds?:       uint | *10
	timeoutSeconds?:      uint | *1
	successThreshold?:    uint | *1
	failureThreshold?:    uint | *3
}

// Container specification
#ContainerSchema: {
	// Name of the container
	name!: string

	// Container image (e.g., "nginx:latest")
	image!: string

	// Image pull policy
	imagePullPolicy: "Always" | "IfNotPresent" | "Never" | *"IfNotPresent"

	// Ports exposed by the container
	ports?: [portName=string]: #PortSchema & {name: portName} // Name is automatically set to the key in the ports map

	// Environment variables for the container
	env?: [envName=string]: #EnvVarSchema & {name: envName} // Name is automatically set to the key in the env map

	// Command to run in the container
	command?: [...string]

	// Arguments to pass to the command
	args?: [...string]

	// Resource requirements for the container
	resources?: #ResourceRequirementsSchema

	// Volume mounts for the container
	volumeMounts?: [string]: #VolumeMountSchema // Name is automatically set to the key in the volumeMounts map

	// Probes for health checking (primarily for sidecar containers).
	// See #ProbeSchema for K8s init container constraints.
	livenessProbe?:  #ProbeSchema
	readinessProbe?: #ProbeSchema
	startupProbe?:   #ProbeSchema
}

#EnvVarSchema: {
	name:   string
	value!: string
}

#ResourceRequirementsSchema: {
	cpu?: {
		request?: number | string & =~"^[0-9]+m$"
		limit?:   number | string & =~"^[0-9]+m$"
	}
	memory?: {
		request?: number | string & =~"^[0-9]+[MG]i$"
		limit?:   number | string & =~"^[0-9]+[MG]i$"
	}
}

//////////////////////////////////////////////////////////////////
//// Scaling Schema
//////////////////////////////////////////////////////////////////

#ScalingSchema: {
	count: int & >=1 & <=1000 | *1
	auto?: #AutoscalingSpec
}

#AutoscalingSpec: {
	min!: int & >=1
	max!: int & >=1
	metrics!: [_, ...#MetricSpec]
	behavior?: {
		scaleUp?: {stabilizationWindowSeconds?: int}
		scaleDown?: {stabilizationWindowSeconds?: int}
	}
}

#MetricSpec: {
	type!:   "cpu" | "memory" | "custom"
	target!: #MetricTargetSpec
	if type == "custom" {
		metricName!: string
	}
}

#MetricTargetSpec: {
	averageUtilization?: int & >=1 & <=100
	averageValue?:       string
}

//////////////////////////////////////////////////////////////////
//// RestartPolicy Schema
//////////////////////////////////////////////////////////////////

#RestartPolicySchema: "Always" | "OnFailure" | "Never" | *"Always"

//////////////////////////////////////////////////////////////////
//// UpdateStrategy Schema
//////////////////////////////////////////////////////////////////

#UpdateStrategySchema: {
	type: "RollingUpdate" | "Recreate" | "OnDelete" | *"RollingUpdate"
	if type == "RollingUpdate" {
		rollingUpdate?: {
			maxUnavailable?: uint | string | *1
			maxSurge?:       uint | string | *1
			partition?:      uint
		}
	}
}

//////////////////////////////////////////////////////////////////
//// HealthCheck Schema
//////////////////////////////////////////////////////////////////

#HealthCheckSchema: {
	livenessProbe?:  #ProbeSchema
	readinessProbe?: #ProbeSchema
	startupProbe?:   #ProbeSchema
}

//////////////////////////////////////////////////////////////////
//// SidecarContainers Schema
//////////////////////////////////////////////////////////////////

#SidecarContainersSchema: [...#ContainerSchema]

//////////////////////////////////////////////////////////////////
//// InitContainers Schema
//////////////////////////////////////////////////////////////////

#InitContainersSchema: [...#ContainerSchema]

//////////////////////////////////////////////////////////////////
//// JobConfig Schema
//////////////////////////////////////////////////////////////////

#JobConfigSchema: {
	completions?:             uint | *1
	parallelism?:             uint | *1
	backoffLimit?:            uint | *6
	activeDeadlineSeconds?:   uint | *300
	ttlSecondsAfterFinished?: uint | *100
}

//////////////////////////////////////////////////////////////////
//// CronJobConfig Schema
//////////////////////////////////////////////////////////////////

#CronJobConfigSchema: {
	scheduleCron!:               string
	concurrencyPolicy?:          "Allow" | "Forbid" | "Replace" | *"Allow"
	startingDeadlineSeconds?:    uint
	successfulJobsHistoryLimit?: uint | *3
	failedJobsHistoryLimit?:     uint | *1
}

//////////////////////////////////////////////////////////////////
//// Stateless Workload Schema
//////////////////////////////////////////////////////////////////

#StatelessWorkloadSchema: close({
	container:          #ContainerSchema
	scaling?:           #ScalingSchema
	restartPolicy?:     #RestartPolicySchema
	updateStrategy?:    #UpdateStrategySchema
	healthCheck?:       #HealthCheckSchema
	sidecarContainers?: #SidecarContainersSchema
	initContainers?:    #InitContainersSchema
	securityContext?:   #SecurityContextSchema
})

//////////////////////////////////////////////////////////////////
//// Stateful Workload Schema
//////////////////////////////////////////////////////////////////

#StatefulWorkloadSchema: close({
	container:          #ContainerSchema
	scaling?:           #ScalingSchema
	restartPolicy?:     #RestartPolicySchema
	updateStrategy?:    #UpdateStrategySchema
	healthCheck?:       #HealthCheckSchema
	sidecarContainers?: #SidecarContainersSchema
	initContainers?:    #InitContainersSchema
	serviceName?:       string
	volumes: [string]: #VolumeSchema
	securityContext?: #SecurityContextSchema
})

//////////////////////////////////////////////////////////////////
//// Daemon Workload Schema
//////////////////////////////////////////////////////////////////

#DaemonWorkloadSchema: close({
	container:          #ContainerSchema
	restartPolicy?:     #RestartPolicySchema
	updateStrategy?:    #UpdateStrategySchema
	healthCheck?:       #HealthCheckSchema
	sidecarContainers?: #SidecarContainersSchema
	initContainers?:    #InitContainersSchema
	securityContext?:   #SecurityContextSchema
})

//////////////////////////////////////////////////////////////////
//// Task Workload Schema
//////////////////////////////////////////////////////////////////

#TaskWorkloadSchema: close({
	container:          #ContainerSchema
	restartPolicy?:     "OnFailure" | "Never" | *"Never"
	jobConfig?:         #JobConfigSchema
	sidecarContainers?: #SidecarContainersSchema
	initContainers?:    #InitContainersSchema
	securityContext?:   #SecurityContextSchema
})

//////////////////////////////////////////////////////////////////
//// Scheduled Task Workload Schema
//////////////////////////////////////////////////////////////////

#ScheduledTaskWorkloadSchema: close({
	container:          #ContainerSchema
	restartPolicy?:     "OnFailure" | "Never" | *"Never"
	cronJobConfig!:     #CronJobConfigSchema
	sidecarContainers?: #SidecarContainersSchema
	initContainers?:    #InitContainersSchema
	securityContext?:   #SecurityContextSchema
})

//////////////////////////////////////////////////////////////////
//// DisruptionBudget Schema
//////////////////////////////////////////////////////////////////

// Availability constraints during voluntary disruptions.
// Exactly one of minAvailable or maxUnavailable must be set.
#DisruptionBudgetSchema: {
	minAvailable!: int | string & =~"^[0-9]+%$"
} | {maxUnavailable!: int | string & =~"^[0-9]+%$"
}

//////////////////////////////////////////////////////////////////
//// GracefulShutdown Schema
//////////////////////////////////////////////////////////////////

// Termination behavior for graceful workload shutdown
#GracefulShutdownSchema: {
	// Grace period before forceful termination (must be non-negative)
	terminationGracePeriodSeconds: uint | *30
	// Command to run before SIGTERM is sent
	preStopCommand?: [...string]
}

//////////////////////////////////////////////////////////////////
//// Placement Schema
//////////////////////////////////////////////////////////////////

// Provider-agnostic workload placement intent
#PlacementSchema: {
	// Failure domain distribution target
	spreadAcross?: *"zones" | "regions" | "hosts"
	// Node/host selection criteria (string-to-string map)
	requirements?: [string]: string
	// Escape hatch for provider-specific placement details
	platformOverrides?: {...}
}
