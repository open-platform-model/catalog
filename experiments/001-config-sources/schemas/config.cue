package schemas

/////////////////////////////////////////////////////////////////
//// Config Schemas
/////////////////////////////////////////////////////////////////

#SecretSchema: {
	type?: string | *"Opaque"
	data: [string]: string // Base64-encoded values
}

// ConfigMap specification
#ConfigMapSchema: {
	data: [string]: string
}

/////////////////////////////////////////////////////////////////
//// Config Source Schema
/////////////////////////////////////////////////////////////////

// A unified abstraction for named configuration sources.
// Each source is either non-sensitive (config) or sensitive (secret),
// with data provided inline or via an external reference.
#ConfigSourceSchema: {
	// Discriminator: "config" for non-sensitive, "secret" for sensitive
	type!: "config" | "secret"

	// Inline key-value data — mutually exclusive with externalRef
	data?: [string]: string

	// Reference to a resource external to the module — mutually exclusive with data
	externalRef?: {
		name!: string
	}

	// Enforce mutual exclusivity: exactly one of data or externalRef must be set
	_hasData:        bool | *false
	_hasExternalRef: bool | *false
	if data != _|_ {
		_hasData: true
	}
	if externalRef != _|_ {
		_hasExternalRef: true
	}

	// At least one must be set
	_hasSource: _hasData | _hasExternalRef
	_hasSource: true
	// Both cannot be set
	if _hasData && _hasExternalRef {
		_conflict: _|_
	}
}
