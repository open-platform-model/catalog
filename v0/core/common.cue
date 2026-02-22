package core

import (
	"strings"
)

#LabelsAnnotationsType: [string]: string | int | bool | [string | int | bool]

// NameType: RFC 1123 DNS label — lowercase alphanumeric with hyphens, max 63 chars
#NameType: string & =~"^[a-z0-9]([a-z0-9-]*[a-z0-9])?$" & strings.MinRunes(1) & strings.MaxRunes(63)

// APIVersionType: domain path with version suffix for metadata.apiVersion fields
// Example: "opmodel.dev/resources/workload@v0"
#APIVersionType: string & =~"^[a-z0-9.-]+(/[a-z0-9.-]+)*@v[0-9]+$" & strings.MinRunes(1) & strings.MaxRunes(254)

#VersionType: string & =~"^\\d+\\.\\d+\\.\\d+(-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?(\\+[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?$"

// FQN (Fully Qualified Name) format: <domain>[/path]@v<major>#<Name>
// Example: opmodel.dev@v0#Container
// Example: opmodel.dev/elements@v1#Container
// Example: github.com/myorg/elements@v1#CustomWorkload
#FQNType: string & =~"^([a-z0-9.-]+(?:/[a-z0-9.-]+)*)@v([0-9]+)#([A-Z][a-zA-Z0-9]*)$"

// UUIDType: RFC 4122 UUID in standard format (lowercase hex)
#UUIDType: string & =~"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"

// OPM namespace UUID for uuid computations via uuid.SHA1 (UUID v5).
// This UUID MUST remain immutable across all versions — it is the root namespace
// for all OPM uuid generation. The CLI uses the same constant.
OPMNamespace: "11bc6112-a6e8-4021-bec9-b3ad246f9466"

// KebabToPascal converts a kebab-case string to PascalCase.
// Usage: (#KebabToPascal & {"in": "stateless-workload"}).out => "StatelessWorkload"
#KebabToPascal: {
	X="in": string
	let _parts = strings.Split(X, "-")
	out: strings.Join([for p in _parts {
		let _runes = strings.Runes(p)
		strings.ToUpper(strings.SliceRunes(p, 0, 1)) + strings.SliceRunes(p, 1, len(_runes))
	}], "")
}
