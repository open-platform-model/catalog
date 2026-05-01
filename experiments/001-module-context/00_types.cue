package module_context

// Minimal type primitives. No stdlib imports — plain regex constraints only.
// These mirror the shape of catalog/core/v1alpha2/types.cue but skip MinRunes/MaxRunes
// (would require strings stdlib import) and any UUID derivation (would require uuid stdlib).

#NameType: string & =~"^[a-z0-9]([a-z0-9-]*[a-z0-9])?$"

#ModulePathType: string & =~"^[a-z0-9.-]+(/[a-z0-9.-]+)*$"

#VersionType: string & =~"^\\d+\\.\\d+\\.\\d+(-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?(\\+[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?$"

#ModuleFQNType: string & =~"^[a-z0-9.-]+(/[a-z0-9.-]+)*/[a-z0-9]([a-z0-9-]*[a-z0-9])?:\\d+\\.\\d+\\.\\d+.*$"

#UUIDType: string & =~"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"

#LabelsAnnotationsType: [string]: string | int | bool | [string | int | bool]
