package claims

// Minimal type primitives. No stdlib imports — plain regex constraints only.
// Mirrors the shape of catalog/core/v1alpha2/types.cue but skips MinRunes/MaxRunes
// (would require strings stdlib import) and any UUID derivation (would require
// uuid stdlib).

#NameType: string & =~"^[a-z0-9]([a-z0-9-]*[a-z0-9])?$"

#ModulePathType: string & =~"^[a-z0-9.-]+(/[a-z0-9.-]+)*$"

#VersionType: string & =~"^\\d+\\.\\d+\\.\\d+(-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?(\\+[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?$"

#MajorVersionType: string & =~"^v\\d+$"

#FQNType: string & =~"^[a-z0-9.-]+(/[a-z0-9.-]+)*/[a-z0-9]([a-z0-9-]*[a-z0-9])?@v\\d+$"

#ModuleFQNType: string & =~"^[a-z0-9.-]+(/[a-z0-9.-]+)*/[a-z0-9]([a-z0-9-]*[a-z0-9])?:\\d+\\.\\d+\\.\\d+.*$"

#UUIDType: string & =~"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"

#LabelsAnnotationsType: [string]: string | int | bool | [string | int | bool]
