# CUE Import Strategy — Grafana JSON Schema

| Field       | Value                          |
| ----------- | ------------------------------ |
| **Status**  | Draft                          |
| **Created** | 2026-03-25                     |
| **Authors** | OPM Contributors               |

---

## Summary

`cue import` converts vendored Grafana JSON Schema files into CUE definition types suitable for use as a validation layer inside `opm/v1alpha1`. CUE v0.16.0 is required for reliable import of Grafana's complex schema combinators.

---

## Supported Import Modes

| Mode         | Extensions    | Notes                                          |
| ------------ | ------------- | ---------------------------------------------- |
| `jsonschema` | `.json`, `.yaml` | Drafts 4, 6, 7, 2019-09, 2020-12 supported |
| `openapi`    | `.json`, `.yaml` | OpenAPI 3.0.0 only; 3.1 not yet supported   |
| `proto`      | `.proto`      | Protocol Buffers                               |
| `json`       | `.json`       | Raw JSON data (not schema)                     |

Use `jsonschema` mode for all Grafana Foundation SDK schema files.

---

## Command Syntax

### Single schema file

```bash
cue import \
  -p grafana \
  -l '#Dashboard:' \
  -f \
  -o catalog/opm/v1alpha1/schemas/vendor/grafana/dashboard_gen.cue \
  catalog/opm/v1alpha1/schemas/vendor/grafana/dashboard.jsonschema.json
```

Flags:

- `-p grafana` — output package name
- `-l '#Dashboard:'` — wrap output in named definition (trailing colon required)
- `-f` — force overwrite existing output file
- `-o path` — output file path

### Importing common types

```bash
cue import \
  -p grafana \
  -l '#Common:' \
  -f \
  -o catalog/opm/v1alpha1/schemas/vendor/grafana/common_gen.cue \
  catalog/opm/v1alpha1/schemas/vendor/grafana/common.jsonschema.json
```

### Importing panel schemas

```bash
# Example: timeseries panel
cue import \
  -p grafana \
  -l '#TimeseriesPanel:' \
  -f \
  -o catalog/opm/v1alpha1/schemas/vendor/grafana/panels/timeseries_gen.cue \
  catalog/opm/v1alpha1/schemas/vendor/grafana/panels/timeseries.jsonschema.json
```

Repeat for each panel schema. See `02-upstream-schema.md` for the full list.

### Batch script (recommended)

Create a shell script `catalog/opm/v1alpha1/schemas/vendor/grafana/import.sh` to automate all imports:

```bash
#!/usr/bin/env bash
set -euo pipefail

BASE=catalog/opm/v1alpha1/schemas/vendor/grafana
OUT=$BASE

cue import -p grafana -l '#Dashboard:' -f \
  -o "$OUT/dashboard_gen.cue" "$BASE/dashboard.jsonschema.json"

cue import -p grafana -l '#Common:' -f \
  -o "$OUT/common_gen.cue" "$BASE/common.jsonschema.json"

for schema in "$BASE/panels/"*.jsonschema.json; do
  name=$(basename "$schema" .jsonschema.json)
  pascal=$(echo "$name" | sed 's/\b./\u&/g; s/ //g')Panel
  cue import -p grafana -l "#${pascal}:" -f \
    -o "$BASE/panels/${name}_gen.cue" "$schema"
done

echo "Import complete. Run: cue vet $BASE/..."
```

---

## Output Format

What `cue import` produces from JSON Schema:

| JSON Schema feature                      | CUE output                          |
| ---------------------------------------- | ----------------------------------- |
| `required: ["name"]` + `properties.name` | `name!: string`                     |
| Optional property                         | `field?: type`                      |
| `default: "browser"`                      | `field?: *"browser" \| string`      |
| `enum: ["a", "b"]`                        | `"a" \| "b"`                        |
| `$ref: "#/$defs/Foo"`                     | `#Foo` (resolved)                   |
| `additionalProperties: false`             | `close({ ... })` (see limitations)  |
| `minimum: 0, maximum: 24`                 | `>=0 & <=24`                        |
| `pattern: "^[a-z]"`                       | `=~"^[a-z]"`                        |

Example input JSON Schema:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["title"],
  "properties": {
    "title": { "type": "string" },
    "timezone": { "type": "string", "default": "browser" },
    "graphTooltip": { "type": "integer", "enum": [0, 1, 2], "default": 0 }
  }
}
```

Produces:

```cue
package grafana

#Dashboard: {
  @jsonschema(schema="https://json-schema.org/draft/2020-12/schema")
  title!:        string
  timezone?:     *"browser" | string
  graphTooltip?: *0 | 0 | 1 | 2
  ...
}
```

---

## Known Limitations

Read this section before running imports.

### oneOf / anyOf / allOf (CUE v0.15.0)

- FAIL in v0.15.0: complex `oneOf/anyOf/allOf` combinators produce import errors
- OK in v0.16.0: `matchN` primitive handles these correctly
- Grafana's dashboard schema uses `oneOf` for panel type discrimination and `anyOf` for flexible field types
- This is the primary reason implementation requires v0.16.0

### additionalProperties: false

- Import does not always produce a `close()` wrapper
- Check each generated file manually
- Add `close({ ... })` wrappers where missing on definitions that must reject unknown fields

### Type conflicts with enum + numeric type

- `type: "number"` combined with `enum: [0, 1, 2]` can produce: "constraint not allowed because type number is excluded"
- Workaround: manually fix generated output to use integer disjunction `0 | 1 | 2`

### Nested schema definitions

- Nested schemas may not auto-extract as separate named definitions
- Review generated output and extract manually if needed

---

## Post-Import Cleanup Checklist

Run after every import session:

- [ ] `cue vet ./catalog/opm/v1alpha1/schemas/vendor/grafana/...` — no evaluation errors
- [ ] Verify `close()` wrappers present on all top-level definitions
- [ ] Fix any `oneOf/anyOf/allOf` errors manually
- [ ] Fix any enum+type conflicts
- [ ] Test against a real Grafana dashboard JSON: `cue vet sample-dashboard.json ./catalog/opm/v1alpha1/schemas/vendor/grafana/dashboard_gen.cue`
- [ ] Document all manual fixups in `IMPORT_NOTES.md`

---

## IMPORT_NOTES.md

Create this file alongside the generated `.cue` files. Format:

```markdown
# Grafana Schema Import Notes

Downloaded: 2026-03-25
Grafana Version: 11.x (Foundation SDK main branch)
CUE Version: v0.16.0

## Download Commands

curl -o dashboard.jsonschema.json \
  https://raw.githubusercontent.com/grafana/grafana-foundation-sdk/main/jsonschema/dashboard.jsonschema.json

## Import Commands

See import.sh

## Manual Fixups Applied

1. dashboard_gen.cue line 42: Added close() around #GridPos definition
   (additionalProperties: false not correctly converted)

2. dashboard_gen.cue line 87: Changed graphTooltip type from number to int
   (enum conflict with numeric type)
```

---

## Re-Import Procedure

On major Grafana releases:

1. Download new schema files (replace existing in `vendor/grafana/`)
2. Run `import.sh`
3. Run `cue vet` and fix any new issues
4. Update `IMPORT_NOTES.md` with new date and version
5. Run full catalog check: `task -C catalog check`
6. Bump `opm/v1alpha1` version: `task -C catalog version:bump DOMAIN=opm TYPE=patch`
