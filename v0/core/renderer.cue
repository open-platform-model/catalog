package core

// Renderer interface
// Renderers convert transformed platform resources into final manifest formats
// for deployment (e.g., Kubernetes YAML, Docker Compose, Terraform)
// #Renderer: {
// 	apiVersion: "core.opm.dev/v0"
// 	kind:       "Renderer"
// 	metadata: {
// 		name!:       #NameType // Example: "kubernetes-list"
// 		description: string    // A brief description of the renderer
// 		version:     string    // The version of the renderer
// 		minVersion?: string    // The minimum version required

// 		// The target platform this renderer produces output for
// 		// Example: "kubernetes", "docker-compose", "terraform", "helm"
// 		targetPlatform!: string

// 		// Labels for renderer categorization and selection
// 		// Example: {"core.opm.dev/format": "kubernetes", "core.opm.dev/output-type": "list"}
// 		labels?: #LabelsAnnotationsType
// 	}

// 	// Render function
// 	// Takes transformed platform resources and produces final output
// 	render: {
// 		// Input: List of transformed resources from transformer execution
// 		// These are platform-specific resources (e.g., K8s Deployments, Services, etc.)
// 		resources: [...]

// 		// Output: Platform-specific manifest with metadata
// 		output: {
// 			// The actual manifest content
// 			// Structure is platform-specific (e.g., K8s List, Helm values, etc.)
// 			manifest: _

// 			// Metadata about the output
// 			metadata: {
// 				// Output format: yaml, json, toml, etc.
// 				format!: "yaml" | "json" | "toml" | "hcl"

// 				// Whether to split output into multiple files
// 				// If true, manifest should be a map[string]_ where keys are filenames
// 				split?: bool | *false

// 				// Optional filename template for split output
// 				// Example: "{{.kind}}-{{.metadata.name}}.yaml"
// 				filenameTemplate?: string

// 				// Additional renderer-specific metadata
// 				[string]: _
// 			}
// 		}
// 	}
// }

// // Map of renderers by name
// #RendererMap: [string]: #Renderer

// NOTE: Removing renderer and decided to only support one rendering process atm, and only in the CLI code.
