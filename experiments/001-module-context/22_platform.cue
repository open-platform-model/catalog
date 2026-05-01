package module_context

// Stub #Platform — minimum needed as #ContextBuilder Layer 1 input.
// 014's #registry / composed-transformer-views / capability tracking omitted.
#Platform: {
	apiVersion: "opmodel.dev/experiments/module_context/v0"
	kind:       "Platform"

	metadata: {
		name!:        #NameType
		description?: string
	}

	#ctx: #PlatformContext
}
