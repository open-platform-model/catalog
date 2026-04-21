package database

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	chk "opmodel.dev/clickhouse_operator/v1alpha1/schemas/clickhouse-keeper.altinity.com/clickhousekeeperinstallation/v1@v1"
)

/////////////////////////////////////////////////////////////////
//// ClickHouseKeeperInstallation Resource Definition
/////////////////////////////////////////////////////////////////

#ClickHouseKeeperInstallationResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/clickhouse-operator/resources/database"
		version:     "v1"
		name:        "clickhouse-keeper-installation"
		description: "A ClickHouse Keeper quorum cluster (clickhouse-keeper.altinity.com/v1)"
		labels: {
			"resource.opmodel.dev/category": "database"
		}
	}

	#defaults: #ClickHouseKeeperInstallationDefaults

	spec: close({clickhouseKeeperInstallation: {
		metadata?: _#metadata
		spec?:     chk.#ClickHouseKeeperInstallationSpec
	}})
}

#ClickHouseKeeperInstallation: component.#Component & {
	#resources: {(#ClickHouseKeeperInstallationResource.metadata.fqn): #ClickHouseKeeperInstallationResource}
}

#ClickHouseKeeperInstallationDefaults: {
	metadata?: _#metadata
	spec?:     chk.#ClickHouseKeeperInstallationSpec
}
