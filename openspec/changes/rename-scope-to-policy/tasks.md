## 1. Core Type Rename — PolicyRule Primitive

- [ ] 1.1 Create `v0/core/policy_rule.cue` with `#PolicyRule` definition (rename from `#Policy`, kind `"PolicyRule"`, remove `metadata.target` field)
- [ ] 1.2 Define `#PolicyRuleMap: [string]: _` in `policy_rule.cue`
- [ ] 1.3 Delete `v0/core/policy.cue` (old primitive file — path will be reused by construct)

## 2. Core Type Rename — Policy Construct

- [ ] 2.1 Create `v0/core/policy.cue` with `#Policy` definition (rename from `#Scope`, kind `"Policy"`, rename `#policies` → `#rules`, reference `#PolicyRule`)
- [ ] 2.2 Add `matchLabels?: #LabelsAnnotationsType` to `appliesTo`, remove old `componentLabels` field
- [ ] 2.3 Make both `matchLabels` and `components` optional in `appliesTo`
- [ ] 2.4 Define `#PolicyMap: [string]: #Policy` in `policy.cue`
- [ ] 2.5 Delete `v0/core/scope.cue`

## 3. Module and ModuleRelease Updates

- [ ] 3.1 Rename `#scopes` → `#policies` in `v0/core/module.cue`, update type to `#Policy`
- [ ] 3.2 Rename `scopes` → `policies` in `v0/core/module_release.cue`, update type and references

## 4. Downstream Consumers — Policies Module

- [ ] 4.1 Update `v0/policies/network/network_rules.cue`: `#NetworkRulesPolicy` extends `core.#PolicyRule`, remove `target` field; `#NetworkRules` extends `core.#Policy`, rename `#policies` → `#rules`
- [ ] 4.2 Update `v0/policies/network/shared_network.cue`: `#SharedNetworkPolicy` extends `core.#PolicyRule`, remove `target` field; `#SharedNetwork` extends `core.#Policy`, rename `#policies` → `#rules`

## 5. Documentation Updates

- [ ] 5.1 Update `docs/core/primitives.md`: rename Policy section → PolicyRule, update descriptions and examples
- [ ] 5.2 Update `docs/core/constructs.md`: rename Scope section → Policy, update description
- [ ] 5.3 Update `docs/core/definition-types.md`: update table, mermaid diagram, and flowchart (Scope → Policy, Policy → PolicyRule)
- [ ] 5.4 Update `docs/core/interface-architecture-rfc.md`: replace Scope references with Policy where applicable

## 6. Validation

- [ ] 6.1 Run `task fmt` to format all CUE files
- [ ] 6.2 Run `task vet` to validate all CUE modules
- [ ] 6.3 Run `task eval MODULE=core` to verify core module evaluates correctly
- [ ] 6.4 Run `task eval MODULE=policies` to verify policies module evaluates correctly
