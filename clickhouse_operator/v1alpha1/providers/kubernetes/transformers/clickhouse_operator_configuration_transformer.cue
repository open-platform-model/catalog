package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/clickhouse_operator/v1alpha1/resources/database@v1"
)

// #ClickHouseOperatorConfigurationTransformer passes ClickHouseOperatorConfiguration
// resources through with OPM context applied (name prefix, namespace, labels).
#ClickHouseOperatorConfigurationTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/clickhouse-operator/providers/kubernetes/transformers"
		version:     "v1"
		name:        "clickhouse-operator-configuration-transformer"
		description: "Passes native ClickHouseOperatorConfiguration resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "database"
			"core.opmodel.dev/resource-type":     "clickhouse-operator-configuration"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#ClickHouseOperatorConfigurationResource.metadata.fqn): res.#ClickHouseOperatorConfigurationResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_choc: #component.spec.clickhouseOperatorConfiguration
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "clickhouse.altinity.com/v1"
			kind:       "ClickHouseOperatorConfiguration"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _choc.metadata != _|_ {
					if _choc.metadata.annotations != _|_ {
						annotations: _choc.metadata.annotations
					}
				}
			}
			if _choc.spec != _|_ {
				spec: _choc.spec
			}
		}
	}
}
