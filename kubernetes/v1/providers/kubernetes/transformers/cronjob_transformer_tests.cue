@if(test)

package transformers

// Test: minimal CronJob with required schedule field
_testCronJobMinimal: (#CronJobTransformer.#transform & {
	#component: {
		metadata: name: "cleanup"
		spec: cronjob: {
			spec: {
				schedule: "0 * * * *"
				jobTemplate: {
					spec: {
						template: {
							spec: {
								containers: [{
									name:  "cleanup"
									image: "busybox:latest"
								}]
								restartPolicy: "OnFailure"
							}
						}
					}
				}
			}
		}
	}
	#context: (#TestCtx & {release: "my-release", namespace: "default", component: "cleanup"}).out
}).output & {
	apiVersion: "batch/v1"
	kind:       "CronJob"
	metadata: {
		name:      "my-release-cleanup"
		namespace: "default"
	}
}
