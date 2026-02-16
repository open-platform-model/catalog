@if(test)

package config

// =============================================================================
// ConfigMap Resource Tests
// =============================================================================

// Test: ConfigMapsResource definition structure
_testConfigMapsResourceDef: #ConfigMapsResource & {
	metadata: {
		apiVersion: "opmodel.dev/resources/config@v0"
		name:       "config-maps"
		fqn:        "opmodel.dev/resources/config@v0#ConfigMaps"
	}
}

// Test: ConfigMaps component helper
_testConfigMapsComponent: #ConfigMaps & {
	metadata: name: "configmap-test"
	spec: configMaps: {
		"app-config": {
			data: {
				"app.conf":     "key=value"
				"logging.conf": "level=info"
			}
		}
	}
}

// Test: Multiple config maps
_testMultipleConfigMaps: #ConfigMaps & {
	metadata: name: "multi-configmap"
	spec: configMaps: {
		"frontend-config": {
			data: "config.json": "{\"theme\": \"dark\"}"
		}
		"backend-config": {
			data: "settings.yaml": "debug: false"
		}
	}
}
