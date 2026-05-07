# Experiment 004 — `#DockerConfigJSON` helper

Probes whether a small CUE helper can produce kubelet-compatible
`.dockerconfigjson` payloads from `(registry, username, password)` inputs,
suitable for dropping into a `#SecretSchema` of type
`kubernetes.io/dockerconfigjson`.

If this works end-to-end the helper graduates to
`opm/v1alpha1/schemas/config.cue` next to `#SecretSchema`, closing the
"OPM has no path for inline registry credentials" gap that surfaced when
shipping `#ImagePullSecretsTrait`.

## Premise

`#ImagePullSecretsTrait` (newly shipped) references pre-existing K8s
Secrets by name. That covers cluster-managed credentials but leaves a
homelab / module-author / CI gap: no way to *mint* the dockerconfigjson
Secret from username + password without hand-crafting the JSON.

The existing `#SecretSchema` already supports
`type: "kubernetes.io/dockerconfigjson"` and renders correctly via
`#SecretTransformer`. The missing piece is just a constructor that
produces the canonical `.dockerconfigjson` string.

A pure-CUE helper using `encoding/base64` (for the `auth` field) and
`encoding/json` (for safe marshalling) avoids hand-built JSON with all
its escape-character hazards.

## Layout

```text
004-docker-config-json/
├── README.md
├── cue.mod/module.cue
├── 00_helper.cue                       # #DockerConfigJSON definition
├── t01_basic_tests.cue                 # registry + user + pwd → expected JSON
├── t02_email_tests.cue                 # optional email field
├── t03_special_chars_tests.cue         # JSON-hazardous + UTF-8 passwords
├── t04_in_secret_tests.cue             # composes inside #SecretSchema-shaped struct
└── n01_missing_required_tests.cue      # missing required field surfaces as error
```

Self-contained. Module path `opmodel.dev/experiments/dockerconfigjson@v0`,
language `v0.16.0`. Package name `dockerconfigjson`. Zero imports beyond
CUE stdlib (`encoding/base64`, `encoding/json`).

## Tests

### Positive (`@if(test)`)

| File | Asserts |
| --- | --- |
| `t01_basic` | three registry styles (GHCR, Docker Hub URL, Harbor with port) produce expected `.dockerconfigjson` string with `auth` correctly base64-encoded |
| `t02_email` | optional `email` field appears in output when present, absent otherwise; pins observed field ordering |
| `t03_special_chars` | password with `"` + `\` survives JSON escaping; UTF-8 password passes through verbatim and base64-encodes the UTF-8 bytes |
| `t04_in_secret` | helper output drops into `#SecretSchema`-shaped struct as `data[".dockerconfigjson"]` without engaging the `#Secret` auto-discovery walker |

Run:

```bash
cue vet -c -t test ./...
```

### Negative

| File | Tag | Asserts |
| --- | --- | --- |
| `n01_missing_required` | `test_negative_missing_registry` | omitting `registry` (required field) surfaces as evaluation error rather than silently producing malformed JSON |

Run:

```bash
! cue vet -c -t test_negative_missing_registry ./...
```

## Helper signature

```cue
#DockerConfigJSON: {
    registry!: string
    username!: string
    password!: string
    email?:    string
    out:       string  // computed .dockerconfigjson
}
```

Single-registry per call. Multi-registry composition belongs at the
caller — building one `auths` map from N entries is a different concern
and would couple this primitive to map-construction conventions.

## Key design choices

- **`json.Marshal` over manual string interpolation** — eliminates
  quote-escape and backslash-escape bugs. CUE's marshaller handles all
  edge cases including UTF-8.
- **`base64.Encode(null, ...)` for the `auth` field** — standard alphabet
  (not URL-safe), matches what `kubectl create secret docker-registry`
  produces.
- **Field ordering pinned in tests** — JSON field order is irrelevant to
  the kubelet but pinning it makes any future CUE evaluator change visible
  here rather than as a silent K8s manifest diff downstream.
- **`email` omitted when absent** — kubelet treats empty-string email as
  configured; absence is a real distinction.

## Promotion criteria

Helper graduates to `opm/v1alpha1/schemas/config.cue` (alongside
`#SecretSchema`) when:

- All `t*` tests pass under `cue vet -c -t test`
- `n01` correctly fails under its negative tag
- A worked example exists showing the helper used inside a real OPM
  module with `#ImagePullSecretsTrait` consuming the named Secret
- (Optional) similar helper sketched for at least one other K8s Secret
  type (e.g. `kubernetes.io/basic-auth`, `kubernetes.io/tls`) to confirm
  the pattern generalises before committing to it as the OPM convention

## Open questions

1. **Slippery slope** — once `#DockerConfigJSON` exists, do we owe
   `#TLSSecret`, `#BasicAuthSecret`, `#SSHAuthSecret`? Each is a
   well-defined K8s Secret-type constructor. The pattern is sound; the
   commitment is real.
2. **Password from `#SecretLiteral`** — the helper currently accepts only
   plain `string` for password. A future iteration could accept
   `string | #SecretLiteral` and extract `.value`, so the cleartext never
   sits in module values when the user prefers the existing #Secret
   pipeline. Outside scope of this experiment because the experiment
   doesn't import the catalog modules.
3. **Multi-registry ergonomics** — if turns out users frequently need
   multiple registries per Secret, a thin `#DockerConfigJSONMulti` taking
   a list might earn its keep. Defer until evidence shows up.
