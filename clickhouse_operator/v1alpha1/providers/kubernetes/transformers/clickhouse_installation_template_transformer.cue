package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/clickhouse_operator/v1alpha1/resources/database@v1"
)

// #ClickHouseInstallationTemplateTransformer passes ClickHouseInstallationTemplate resources through
// with OPM context applied (name prefix, namespace, labels).
#ClickHouseInstallationTemplateTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/clickhouse-operator/providers/kubernetes/transformers"
		version:     "v1"
		name:        "clickhouse-installation-template-transformer"
		description: "Passes native ClickHouseInstallationTemplate resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "database"
			"core.opmodel.dev/resource-type":     "clickhouse-installation-template"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#ClickHouseInstallationTemplateResource.metadata.fqn): res.#ClickHouseInstallationTemplateResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_chit: #component.spec.clickhouseInstallationTemplate
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "clickhouse.altinity.com/v1"
			kind:       "ClickHouseInstallationTemplate"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _chit.metadata != _|_ {
					if _chit.metadata.annotations != _|_ {
						annotations: _chit.metadata.annotations
					}
				}
			}
			if _chit.spec != _|_ {
				spec: _chit.spec
			}
		}
	}
}
