package testkit

// #Tests is a map from group name to test cases.
// Pattern constraint keeps it open so multiple files can contribute groups.
#Tests: [string]: [...#Test]

// #Test defines a single test case.
#Test: {
	// Human-readable test name.
	name!: string

	// The CUE definition to test against (direct reference, not a string).
	// Example: definition: #PortSchema
	definition!: _

	// Input data to unify with the definition.
	// This is NOT evaluated against the definition in CUE —
	// the Go runner performs the unification.
	input!: _

	// Assertions about the unification result.
	assert!: #Assert
}

// #Assert specifies what should happen when input is unified with the definition.
#Assert: {
	// Must the unification succeed? Default: true.
	valid: *true | bool

	// CUE expression unified with the result (valid=true only).
	// The Go runner walks the tree and checks each leaf against the result.
	// Supports any CUE constraint: exact values, regex (=~"..."), bounds (>=1), etc.
	// Example: output: metadata: fqn: "opmodel.dev/resources/workload@v0#Container"
	// Example: output: spec: scaling: count: >=1 & <=1000
	output?: _

	// CUE constraint on the error string (valid=false only).
	// Example: error: =~"not allowed"
	// Example: error: =~"field is required"
	error?: _
}
