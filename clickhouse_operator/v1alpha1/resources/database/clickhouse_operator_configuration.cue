package database

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	choc "opmodel.dev/clickhouse_operator/v1alpha1/schemas/clickhouse.altinity.com/clickhouseoperatorconfiguration/v1@v1"
)

/////////////////////////////////////////////////////////////////
//// ClickHouseOperatorConfiguration Resource Definition
/////////////////////////////////////////////////////////////////

#ClickHouseOperatorConfigurationResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/clickhouse-operator/resources/database"
		version:     "v1"
		name:        "clickhouse-operator-configuration"
		description: "Operator-scoped configuration override (clickhouse.altinity.com/v1)"
		labels: {
			"resource.opmodel.dev/category": "database"
		}
	}

	#defaults: #ClickHouseOperatorConfigurationDefaults

	spec: close({clickhouseOperatorConfiguration: {
		metadata?: _#metadata
		spec?:     choc.#ClickHouseOperatorConfigurationSpec
	}})
}

#ClickHouseOperatorConfiguration: component.#Component & {
	#resources: {(#ClickHouseOperatorConfigurationResource.metadata.fqn): #ClickHouseOperatorConfigurationResource}
}

#ClickHouseOperatorConfigurationDefaults: {
	metadata?: _#metadata
	spec?:     choc.#ClickHouseOperatorConfigurationSpec
}
