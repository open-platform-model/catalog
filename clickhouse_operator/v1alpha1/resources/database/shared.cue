package database

// _#metadata is a shared optional metadata struct for annotation passthrough.
// Used by all ClickHouse operator resource wrappers in this package.
_#metadata: {
	name?:      string
	namespace?: string
	labels?: {[string]: string}
	annotations?: {[string]: string}
}
