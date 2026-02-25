package schemas

/////////////////////////////////////////////////////////////////
//// Common Schemas
/////////////////////////////////////////////////////////////////

// Labels and annotations schema
#LabelsAnnotationsSchema: [string]: string | int | bool | [string | int | bool]

// Semantic version schema
#VersionSchema: string & =~"^\\d+\\.\\d+\\.\\d+(-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?(\\+[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?$"
