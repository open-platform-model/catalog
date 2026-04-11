// K8up backup schemas for OPM native resource definitions.
// Open schemas that accept the full K8up CR specs with passthrough semantics.
package schemas

// #ScheduleSchema accepts the full K8up Schedule spec.
// A Schedule creates recurring Backup, Check, and Prune jobs.
#ScheduleSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		backend?: {
			repoPasswordSecretRef?: {
				name?: string
				key?:  string
				...
			}
			s3?: {
				endpoint?: string
				bucket?:   string
				accessKeyIDSecretRef?: {
					name?: string
					key?:  string
					...
				}
				secretAccessKeySecretRef?: {
					name?: string
					key?:  string
					...
				}
				...
			}
			...
		}
		backup?: {
			schedule?: string
			...
		}
		check?: {
			schedule?: string
			...
		}
		prune?: {
			schedule?: string
			retention?: {
				keepLast?:    int
				keepDaily?:   int
				keepWeekly?:  int
				keepMonthly?: int
				keepYearly?:  int
				keepHourly?:  int
				keepTags?: [...string]
				...
			}
			...
		}
		archive?: {
			schedule?: string
			...
		}
		...
	}
	...
}

// #PreBackupPodSchema accepts the full K8up PreBackupPod spec.
// A PreBackupPod runs a command before each backup for consistency (e.g. database checkpoints).
#PreBackupPodSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		backupCommand?: string
		fileExtension?: string
		pod?: {
			spec?: {
				containers?: [...]
				volumes?: [...]
				...
			}
			...
		}
		...
	}
	...
}

// #BackupSchema accepts the full K8up Backup spec.
// A one-off backup resource.
#BackupSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		backend?: {...}
		...
	}
	...
}

// #RestoreSchema accepts the full K8up Restore spec.
// Restores data from a restic repository.
#RestoreSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		backend?: {...}
		snapshot?: string
		restoreMethod?: {
			folder?: {
				claimName?: string
				...
			}
			s3?: {...}
			...
		}
		...
	}
	...
}
