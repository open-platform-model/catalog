@if(test)

package config

import (
	tst "experiments.dev/test-framework/testkit"
)

#tests: tst.#Tests & {

	// =========================================================================
	// #ConfigMapsResource — closedness of the resource definition
	// =========================================================================

	configMapsResource: [
		{
			name:       "valid resource metadata"
			definition: "#ConfigMapsResource"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Resource"
				metadata: {
					apiVersion:  "opmodel.dev/resources/config@v0"
					name:        "config-maps"
					description: "A ConfigMap definition for external configuration"
				}
			}
			assert: {
				valid:    true
				concrete: false
				fields: {
					"metadata.fqn": equals: "opmodel.dev/resources/config@v0#ConfigMaps"
				}
			}
		},
		{
			name:       "rejects extra field at root"
			definition: "#ConfigMapsResource"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Resource"
				metadata: {
					apiVersion: "opmodel.dev/resources/config@v0"
					name:       "config-maps"
				}
				bogus: "should-fail"
			}
			assert: valid: false
		},
		{
			name:       "rejects extra field in metadata"
			definition: "#ConfigMapsResource"
			input: {
				apiVersion: "opmodel.dev/core/v0"
				kind:       "Resource"
				metadata: {
					apiVersion: "opmodel.dev/resources/config@v0"
					name:       "config-maps"
					bogus:      "should-fail"
				}
			}
			assert: valid: false
		},
	]

	// =========================================================================
	// #ConfigMaps — component closedness (spec: close({_allFields}))
	// =========================================================================

	configMapsComponent: [
		{
			name:       "valid configmaps component"
			definition: "#ConfigMaps"
			input: {
				metadata: name: "my-config"
				spec: configMaps: "app-config": data: {
					"key1": "value1"
					"key2": "value2"
				}
			}
			assert: valid: true
		},
		{
			name:       "valid with multiple configmaps"
			definition: "#ConfigMaps"
			input: {
				metadata: name: "configs"
				spec: configMaps: {
					"app-config": data: "key": "value"
					"db-config": data: "host": "localhost"
				}
			}
			assert: valid: true
		},
		{
			name:       "rejects extra field in spec (closedness)"
			definition: "#ConfigMaps"
			input: {
				metadata: name: "my-config"
				spec: {
					configMaps: "app-config": data: "key": "value"
					bogus: "should-fail"
				}
			}
			assert: valid: false
		},
	]
}
