# CUE + Grafana Ecosystem Survey

| Field       | Value                          |
| ----------- | ------------------------------ |
| **Status**  | Draft                          |
| **Created** | 2026-03-25                     |
| **Authors** | OPM Contributors               |

---

## Summary

Survey of existing CUE-based Grafana dashboard tooling as of Q1 2026. No existing tool provides the composability OPM requires; native support is necessary.

---

## Third-Party Tools

### cuemon

- Repo: https://github.com/sivukhin/cuemon
- Stars: 5, last commit: August 2024, language: Go
- Single maintainer; no forks
- CLI that converts Grafana JSON dashboards to and from CUE format
- Commands: `bootstrap` (JSON to CUE), `update` (integrate new panel JSON)
- Supports Grafana v10+; vendored `grafanaV10.cue` schema included
- Maturity: early/experimental — no composability primitives; insufficient for OPM's Resource and Trait model

### Duologic/grafana-spec

- Repo: https://github.com/Duologic/grafana-spec
- Stars: 0, archived
- Proof-of-concept for generating Grafana specs in CUE
- README states: "POC for generating a Grafana spec, Thema has this built-in now" (https://github.com/Duologic/grafana-spec)
- Status: superseded; historical reference only

---

## Official Grafana CUE Infrastructure

### Grafana's internal CUE usage

Grafana maintains 394+ `.cue` files in `grafana/grafana` (https://github.com/grafana/grafana). All resource types — dashboards, panels, plugins — are defined first in CUE. CUE is the schema source of truth; generated code in Go, TypeScript, Python, PHP, and Java is derived from it.

### Cog

- Repo: https://github.com/grafana/cog
- Stars: 95, v0.1.4 released February 2026
- Reads CUE, JSON Schema, and OpenAPI; generates SDK code in multiple target languages
- Actively maintained; used in production at Grafana Labs
- Users do not write CUE; Cog consumes it to produce language-native builders

### Grafana Foundation SDK

- Repo: https://github.com/grafana/grafana-foundation-sdk
- Stars: 218
- Fully generated from Grafana's CUE schemas via Cog
- Languages: Go, TypeScript, Python, PHP, Java
- Publishes JSON Schema and OpenAPI artifacts in `jsonschema/` and `openapi/` directories
- Recommended by Grafana for dashboard-as-code (2025-2026) (https://github.com/grafana/grafana-foundation-sdk)
- Users write SDK code in their language of choice; CUE is not user-facing

### Thema

- Repo: https://github.com/grafana/thema
- Stars: 236, no longer actively maintained (archived)
- CUE-based schema versioning framework; replaced by kindsys and Cog
- Historical reference only

### kindsys

- Repo: https://github.com/grafana/kindsys
- Runtime system for CUE-defined object types; core to Grafana's internal architecture
- Not user-facing; not a dependency candidate for OPM

### cuetsy

- Repo: https://github.com/grafana/cuetsy
- CUE to TypeScript type exporter; marked experimental
- Used internally by the Grafana frontend; not user-facing

---

## Grafana's 2025-2026 Strategy

Grafana doubled down on CUE internally — more `.cue` files than any prior release — while deliberately steering users away from authoring CUE directly. The Grafana 12 strategy (https://grafana.com/blog/2024/11/18/grafana-12-preview/) is API-first: the CUE schemas are internal plumbing, Cog generates the SDKs, and the Foundation SDK is the officially recommended dashboard-as-code path. Dashboard Schema v2beta1 (experimental) was introduced in this cycle. End users write Go, TypeScript, or Python; CUE authorship is a Grafana Labs internal concern.

---

## Perses

- Site: https://perses.dev/
- Alternative open-source dashboard platform with native CUE integration
- Plugins defined entirely in CUE; `migrate.cue` files handle Grafana-to-Perses migration
- Demonstrates that CUE is a viable user-facing dashboard definition language when the platform is designed for it from the start
- Not Grafana-compatible at runtime; relevant as prior art for CUE-first dashboard design

---

## Comparison Table

| Approach          | Language                    | Ecosystem        | Grafana Official   | Composability                         |
| ----------------- | --------------------------- | ---------------- | ------------------ | ------------------------------------- |
| Foundation SDK    | Go / TS / Python / PHP / Java | Growing        | Yes                | Low (imperative builders)             |
| Grafonnet         | Jsonnet                     | Large (28+ tools) | Community         | Medium                                |
| Grizzly           | CLI + Jsonnet               | Medium           | Grafana-maintained | Medium                                |
| cuemon            | CUE                         | 1 tool           | No                 | Low                                   |
| OPM (this design) | CUE                         | N/A              | No                 | High (unification, Traits, Resources) |
| Perses            | CUE                         | Small            | No                 | High                                  |

---

## Assessment

The CUE + Grafana ecosystem is intentionally small on the user-facing side. No existing tool provides the composability OPM requires: Resources, Traits, Blueprints, and Bundle-level dashboard composition. cuemon addresses JSON-to-CUE conversion only and has no module model. The Foundation SDK is the correct reference for schema fidelity but is not a dependency or authoring model. Building native OPM support is the correct choice: OPM's CUE-first design makes dashboard definitions a natural extension of the existing module system.

---

## Why Not Use Foundation SDK Directly

- The Foundation SDK generates multi-language code; OPM requires CUE as the authoring and validation language
- The SDK uses imperative builders; OPM uses declarative CUE unification
- The SDK has no module composability: no Resources, Traits, or Blueprints
- The SDK is a runtime code dependency; OPM requires schema validation at `cue vet` time with no external runtime
