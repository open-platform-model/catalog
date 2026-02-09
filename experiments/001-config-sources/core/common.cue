package core

import (
	"strings"
)

#LabelsAnnotationsType: [string]: string | int | bool | [string | int | bool]

// NameType: RFC 1123 DNS label — lowercase alphanumeric with hyphens, max 63 chars
#NameType: string & =~"^[a-z0-9]([a-z0-9-]*[a-z0-9])?$" & strings.MinRunes(1) & strings.MaxRunes(63)

// APIVersionType: domain path with version suffix for metadata.apiVersion fields
// Example: "example.com/config-sources/resources/workload"
#APIVersionType: string & =~"^[a-z0-9.-]+(/[a-z0-9.-]+)*@v[0-9]+$" & strings.MinRunes(1) & strings.MaxRunes(254)

#VersionType: string & =~"^\\d+\\.\\d+\\.\\d+(-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?(\\+[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?$"

// FQN (Fully Qualified Name) format: <domain>[/path]@v<major>#<Name>
// Example: opmodel.dev@v0#Container
// Example: opmodel.dev/elements@v1#Container
// Example: github.com/myorg/elements@v1#CustomWorkload
#FQNType: string & =~"^([a-z0-9.-]+(?:/[a-z0-9.-]+)*)@v([0-9]+)#([A-Z][a-zA-Z0-9]*)$"

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
