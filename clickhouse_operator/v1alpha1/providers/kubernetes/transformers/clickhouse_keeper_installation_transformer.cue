package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/clickhouse_operator/v1alpha1/resources/database@v1"
)

// #ClickHouseKeeperInstallationTransformer passes ClickHouseKeeperInstallation resources through
// with OPM context applied (name prefix, namespace, labels).
#ClickHouseKeeperInstallationTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/clickhouse-operator/providers/kubernetes/transformers"
		version:     "v1"
		name:        "clickhouse-keeper-installation-transformer"
		description: "Passes native ClickHouseKeeperInstallation resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "database"
			"core.opmodel.dev/resource-type":     "clickhouse-keeper-installation"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#ClickHouseKeeperInstallationResource.metadata.fqn): res.#ClickHouseKeeperInstallationResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_chk:  #component.spec.clickhouseKeeperInstallation
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "clickhouse-keeper.altinity.com/v1"
			kind:       "ClickHouseKeeperInstallation"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _chk.metadata != _|_ {
					if _chk.metadata.annotations != _|_ {
						annotations: _chk.metadata.annotations
					}
				}
			}
			if _chk.spec != _|_ {
				spec: _chk.spec
			}
		}
	}
}
