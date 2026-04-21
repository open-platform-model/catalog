@if(test)

package transformers

// Test: minimal ClickHouseInstallation passthrough
_testClickHouseInstallationMinimal: (#ClickHouseInstallationTransformer.#transform & {
	#component: {
		metadata: name: "telemetry"
		spec: clickhouseInstallation: {
			spec: configuration: clusters: [{
				name: "default"
				layout: {
					shardsCount:   1
					replicasCount: 1
				}
			}]
		}
	}
	#context: (#TestCtx & {release: "clickstack", namespace: "observability", component: "telemetry"}).out
}).output & {
	apiVersion: "clickhouse.altinity.com/v1"
	kind:       "ClickHouseInstallation"
	metadata: {
		name:      "clickstack-telemetry"
		namespace: "observability"
	}
}

// Test: minimal ClickHouseKeeperInstallation passthrough
_testClickHouseKeeperInstallationMinimal: (#ClickHouseKeeperInstallationTransformer.#transform & {
	#component: {
		metadata: name: "keeper"
		spec: clickhouseKeeperInstallation: {
			spec: configuration: clusters: [{
				name: "default"
				layout: replicasCount: 3
			}]
		}
	}
	#context: (#TestCtx & {release: "clickstack", namespace: "observability", component: "keeper"}).out
}).output & {
	apiVersion: "clickhouse-keeper.altinity.com/v1"
	kind:       "ClickHouseKeeperInstallation"
	metadata: {
		name:      "clickstack-keeper"
		namespace: "observability"
	}
}
