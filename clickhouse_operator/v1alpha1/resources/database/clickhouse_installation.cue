package database

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	chi "opmodel.dev/clickhouse_operator/v1alpha1/schemas/clickhouse.altinity.com/clickhouseinstallation/v1@v1"
)

/////////////////////////////////////////////////////////////////
//// ClickHouseInstallation Resource Definition
/////////////////////////////////////////////////////////////////

#ClickHouseInstallationResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/clickhouse-operator/resources/database"
		version:     "v1"
		name:        "clickhouse-installation"
		description: "An Altinity ClickHouseInstallation cluster (clickhouse.altinity.com/v1)"
		labels: {
			"resource.opmodel.dev/category": "database"
		}
	}

	#defaults: #ClickHouseInstallationDefaults

	spec: close({clickhouseInstallation: {
		metadata?: _#metadata
		spec?:     chi.#ClickHouseInstallationSpec
	}})
}

#ClickHouseInstallation: component.#Component & {
	#resources: {(#ClickHouseInstallationResource.metadata.fqn): #ClickHouseInstallationResource}
}

#ClickHouseInstallationDefaults: {
	metadata?: _#metadata
	spec?:     chi.#ClickHouseInstallationSpec
}
