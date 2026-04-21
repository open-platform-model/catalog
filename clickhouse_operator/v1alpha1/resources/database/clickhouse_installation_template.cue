package database

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	chit "opmodel.dev/clickhouse_operator/v1alpha1/schemas/clickhouse.altinity.com/clickhouseinstallationtemplate/v1@v1"
)

/////////////////////////////////////////////////////////////////
//// ClickHouseInstallationTemplate Resource Definition
/////////////////////////////////////////////////////////////////

#ClickHouseInstallationTemplateResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/clickhouse-operator/resources/database"
		version:     "v1"
		name:        "clickhouse-installation-template"
		description: "A reusable ClickHouseInstallationTemplate (clickhouse.altinity.com/v1)"
		labels: {
			"resource.opmodel.dev/category": "database"
		}
	}

	#defaults: #ClickHouseInstallationTemplateDefaults

	spec: close({clickhouseInstallationTemplate: {
		metadata?: _#metadata
		spec?:     chit.#ClickHouseInstallationTemplateSpec
	}})
}

#ClickHouseInstallationTemplate: component.#Component & {
	#resources: {(#ClickHouseInstallationTemplateResource.metadata.fqn): #ClickHouseInstallationTemplateResource}
}

#ClickHouseInstallationTemplateDefaults: {
	metadata?: _#metadata
	spec?:     chit.#ClickHouseInstallationTemplateSpec
}
