## 1. Core Type Rename — PolicyRule Primitive

- [x] 1.1 Create `v0/core/policy_rule.cue` with `#PolicyRule` definition (rename from `#Policy`, kind `"PolicyRule"`, remove `metadata.target` field)
- [x] 1.2 Define `#PolicyRuleMap: [string]: _` in `policy_rule.cue`
- [x] 1.3 Delete `v0/core/policy.cue` (old primitive file — path will be reused by construct)

## 2. Core Type Rename — Policy Construct

- [x] 2.1 Create `v0/core/policy.cue` with `#Policy` definition (rename from `#Scope`, kind `"Policy"`, rename `#policies` → `#rules`, reference `#PolicyRule`)
- [x] 2.2 Add `matchLabels?: #LabelsAnnotationsType` to `appliesTo`, remove old `componentLabels` field
- [x] 2.3 Make both `matchLabels` and `components` optional in `appliesTo`
- [x] 2.4 Define `#PolicyMap: [string]: #Policy` in `policy.cue`
- [x] 2.5 Delete `v0/core/scope.cue`

## 3. Module and ModuleRelease Updates

- [x] 3.1 Rename `#scopes` → `#policies` in `v0/core/module.cue`, update type to `#Policy`
- [x] 3.2 Rename `scopes` → `policies` in `v0/core/module_release.cue`, update type and references

## 4. Downstream Consumers — Policies Module

- [x] 4.1 Update `v0/policies/network/network_rules.cue`: `#NetworkRulesPolicy` extends `core.#PolicyRule`, remove `target` field; `#NetworkRules` extends `core.#Policy`, rename `#policies` → `#rules`
- [x] 4.2 Update `v0/policies/network/shared_network.cue`: `#SharedNetworkPolicy` extends `core.#PolicyRule`, remove `target` field; `#SharedNetwork` extends `core.#Policy`, rename `#policies` → `#rules`

## 5. Documentation Updates

- [x] 5.1 Update `docs/core/primitives.md`: rename Policy section → PolicyRule, update descriptions and examples
- [x] 5.2 Update `docs/core/constructs.md`: rename Scope section → Policy, update description
- [x] 5.3 Update `docs/core/definition-types.md`: update table, mermaid diagram, and flowchart (Scope → Policy, Policy → PolicyRule)
- [x] 5.4 Update `docs/core/interface-architecture-rfc.md`: replace Scope references with Policy where applicable

## 6. Validation

- [x] 6.1 Run `task fmt` to format all CUE files
- [x] 6.2 Run `task vet` to validate all CUE modules
- [x] 6.3 Run `task eval MODULE=core` to verify core module evaluates correctly
- [x] 6.4 Run `task eval MODULE=policies` to verify policies module evaluates correctly
