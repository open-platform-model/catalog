package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/clickhouse_operator/v1alpha1/resources/database@v1"
)

// #ClickHouseInstallationTransformer passes native ClickHouseInstallation resources through
// with OPM context applied (name prefix, namespace, labels).
#ClickHouseInstallationTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/clickhouse-operator/providers/kubernetes/transformers"
		version:     "v1"
		name:        "clickhouse-installation-transformer"
		description: "Passes native ClickHouseInstallation resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "database"
			"core.opmodel.dev/resource-type":     "clickhouse-installation"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#ClickHouseInstallationResource.metadata.fqn): res.#ClickHouseInstallationResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_chi:  #component.spec.clickhouseInstallation
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "clickhouse.altinity.com/v1"
			kind:       "ClickHouseInstallation"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _chi.metadata != _|_ {
					if _chi.metadata.annotations != _|_ {
						annotations: _chi.metadata.annotations
					}
				}
			}
			if _chi.spec != _|_ {
				spec: _chi.spec
			}
		}
	}
}
