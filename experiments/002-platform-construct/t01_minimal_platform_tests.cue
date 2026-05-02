@if(test)

package platform_construct

// T01 — A bare #Platform with an empty #registry vets clean and produces
// empty projections. Anchors the "registry as sole composition ingress"
// claim (014 D1) — nothing else is required for a valid Platform value.

_t01_platform: #Platform & {
	metadata: name: "minimal"
	type: "kubernetes"
	#registry: {}
}

t01_knownResourcesEmpty:      len(_t01_platform.#knownResources) & 0
t01_knownTraitsEmpty:         len(_t01_platform.#knownTraits) & 0
t01_knownClaimsEmpty:         len(_t01_platform.#knownClaims) & 0
t01_composedTransformersZero: len(_t01_platform.#composedTransformers) & 0
t01_matchersResourcesEmpty:   len(_t01_platform.#matchers.resources) & 0
t01_matchersTraitsEmpty:      len(_t01_platform.#matchers.traits) & 0
t01_matchersClaimsEmpty:      len(_t01_platform.#matchers.claims) & 0
t01_invalidEmpty:             0 & (len(_t01_platform.#matchers._invalid.resources) +
	len(_t01_platform.#matchers._invalid.traits) +
	len(_t01_platform.#matchers._invalid.claims))
