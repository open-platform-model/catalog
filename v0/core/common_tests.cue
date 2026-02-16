@if(test)

package core

// =============================================================================
// Common Type Tests
// =============================================================================

// ── NameType Tests ────────────────────────────────────────────────
// Valid names
_testNameSimple:      #NameType & "web"
_testNameHyphenated:  #NameType & "my-resource"
_testNameMultiHyphen: #NameType & "my-multi-word-name"
_testNameWithNumbers: #NameType & "web-v2"
_testNameSingleChar:  #NameType & "x"
_testNameMaxLen:      #NameType & "a-very-long-name-that-is-still-within-the-sixty-three-char-lim"

// ── APIVersionType Tests ──────────────────────────────────────────
// Valid API versions
_testAPIVersionSimple:  #APIVersionType & "opmodel.dev@v0"
_testAPIVersionNested:  #APIVersionType & "opmodel.dev/resources/workload@v0"
_testAPIVersionHighVer: #APIVersionType & "opmodel.dev/core@v12"
_testAPIVersionCustom:  #APIVersionType & "mycompany.io/custom@v1"

// ── VersionType Tests ─────────────────────────────────────────────
// Valid semver versions
_testVersionBasic:      #VersionType & "0.1.0"
_testVersionStable:     #VersionType & "1.0.0"
_testVersionPreRelease: #VersionType & "1.0.0-alpha.1"
_testVersionBuild:      #VersionType & "1.0.0+build.123"
_testVersionFull:       #VersionType & "1.0.0-beta.2+build.456"

// ── FQNType Tests ─────────────────────────────────────────────────
// Valid FQNs
_testFQNSimple:  #FQNType & "opmodel.dev@v0#Container"
_testFQNNested:  #FQNType & "opmodel.dev/resources/workload@v0#Container"
_testFQNCustom:  #FQNType & "mycompany.io/elements@v1#CustomWorkload"
_testFQNHighVer: #FQNType & "github.com/myorg/elements@v12#Widget"

// ── UUIDType Tests ────────────────────────────────────────────────
_testUUID: #UUIDType & "550e8400-e29b-41d4-a716-446655440000"

// ── KebabToPascal Tests ──────────────────────────────────────────
_testKebabSimple: (#KebabToPascal & {in: "container"}).out & "Container"
_testKebabMulti: (#KebabToPascal & {in: "stateless-workload"}).out & "StatelessWorkload"
_testKebabTriple: (#KebabToPascal & {in: "my-multi-word"}).out & "MyMultiWord"
_testKebabSingle: (#KebabToPascal & {in: "x"}).out & "X"
