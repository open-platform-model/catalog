@if(test)

package core

// =============================================================================
// Template Definition Tests
// =============================================================================

// Test: minimal module template
_testTemplateModule: #Template & {
	metadata: {
		apiVersion: "test.dev/templates@v0"
		name:       "basic-module"
		category:   "module"
	}
}

// Test: minimal bundle template
_testTemplateBundle: #Template & {
	metadata: {
		apiVersion: "test.dev/templates@v0"
		name:       "basic-bundle"
		category:   "bundle"
	}
}

// Test: template with all optional fields
_testTemplateFull: #Template & {
	metadata: {
		apiVersion:  "test.dev/templates@v0"
		name:        "advanced-module"
		category:    "module"
		description: "An advanced module template"
		level:       "advanced"
		useCase:     "microservice"
		labels: {
			"test.dev/framework": "go"
		}
		annotations: {
			"test.dev/docs": "https://example.com"
		}
	}
}

// Test: template at each level
_testTemplateBeginner: #Template & {
	metadata: {
		apiVersion: "test.dev/templates@v0"
		name:       "beginner-template"
		category:   "module"
		level:      "beginner"
	}
}

_testTemplateIntermediate: #Template & {
	metadata: {
		apiVersion: "test.dev/templates@v0"
		name:       "intermediate-template"
		category:   "module"
		level:      "intermediate"
	}
}
