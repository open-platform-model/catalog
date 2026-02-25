package testkit

// #Tests is a map from group name to test cases.
// Pattern constraint keeps it open so multiple files can contribute groups.
#Tests: [string]: [...#Test]

// #Test defines a single test case.
#Test: {
	// Human-readable test name.
	name!: string

	// Reference to the CUE definition to test against.
	// Example: "#PortSchema", "#NormalizeCPU", "#Resource"
	definition!: string

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

	// Whether to require all fields to be concrete. Default: true.
	// Set to false for definitions with hidden inconcrete fields (e.g., #spec).
	concrete: *true | bool

	// --- Assertions for valid=true ---

	// Exact match: the full output must equal this value.
	equal?: _

	// Subset match: the output must contain these fields/values.
	contains?: _

	// Per-field assertions on the output.
	fields?: [string]: #FieldCheck

	// --- Assertions for valid=false ---

	// The error message must contain this substring.
	errorContains?: string

	// The error must relate to this field path.
	errorPath?: string
}

// #FieldCheck defines assertions on a single field in the output.
#FieldCheck: {
	// The field's value must equal this.
	equals?: _

	// The field's string value must match this regex.
	matches?: string

	// The field must be of this CUE type.
	type?: "string" | "int" | "float" | "bool" | "struct" | "list"

	// Numeric bound checks.
	greaterThan?:    number
	lessThan?:       number
	greaterOrEqual?: number
	lessOrEqual?:    number

	// String length checks.
	minLength?: int
	maxLength?: int

	// Existence checks.
	required?: bool
	absent?:   bool
}
