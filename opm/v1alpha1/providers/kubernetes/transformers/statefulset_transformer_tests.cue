@if(test)

package transformers

// =============================================================================
// StatefulsetTransformer Tests
// =============================================================================
//
// Run: cue vet -t test ./providers/kubernetes/transformers/...
// Or:  task test   (from catalog/)

// Test: Minimal stateful component produces a structurally valid StatefulSet.
// Asserts: apiVersion, kind, name convention ("{release}-{component}"), namespace.
_testStatefulsetMinimal: (#StatefulsetTransformer.#transform & {
	#component: {
		metadata: name: "db"
		spec: container: {
			name: "db"
			image: {
				repository: "mariadb"
				tag:        "12.0"
				digest:     ""
				pullPolicy: "IfNotPresent"
				reference:  "mariadb:12.0"
			}
		}
	}
	#context: (#TestCtx & {
		release:   "data"
		namespace: "default"
		component: "db"
	}).out
}).output & {
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata: {
		name:      "data-db"
		namespace: "default"
	}
	spec: serviceName: "data-db"
}

// Test: Component with podMetadata trait sets pod-template annotations + labels.
// Asserts: spec.template.metadata.{annotations,labels} carry the podMetadata
// values (pod-scoped), and the standard component labels remain on the template.
// This is the pod-scoped channel the k8up annotation-based backup relies on.
_testStatefulsetPodMetadata: (#StatefulsetTransformer.#transform & {
	#component: {
		metadata: name: "db"
		spec: {
			container: {
				name: "db"
				image: {
					repository: "mariadb"
					tag:        "12.0"
					digest:     ""
					pullPolicy: "IfNotPresent"
					reference:  "mariadb:12.0"
				}
			}
			podMetadata: {
				annotations: {
					"k8up.io/backupcommand":           "mariadb-dump --single-transaction --all-databases"
					"k8up.io/backupcommand-container": "db"
					"k8up.io/file-extension":          ".sql"
				}
				labels: "backup.opmodel.dev/enabled": "true"
			}
		}
	}
	#context: (#TestCtx & {
		release:   "data"
		namespace: "default"
		component: "db"
	}).out
}).output & {
	spec: template: metadata: {
		annotations: {
			"k8up.io/backupcommand":           "mariadb-dump --single-transaction --all-databases"
			"k8up.io/backupcommand-container": "db"
			"k8up.io/file-extension":          ".sql"
		}
		labels: {
			"backup.opmodel.dev/enabled": "true"
			"app.kubernetes.io/name":     "db"
		}
	}
}
