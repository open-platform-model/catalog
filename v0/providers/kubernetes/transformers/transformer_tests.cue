@if(test)

package transformers

// =============================================================================
// Transformer Structural Compatibility Tests
//
// These tests verify that transformer output is structurally compatible with
// the Kubernetes API schema (k8s type unification succeeds without error).
//
// WHY NO value assertions:
//   k8s resource fields use `#Quantity = number | string`, so accessing
//   `.resources.limits.cpu` always yields `number | string` — a non-concrete
//   type that `cue vet -c` rejects. Value-level normalization is tested in
//   quantity_tests.cue (schemas module) via #NormalizeCPU / #NormalizeMemory directly.
//
//   Structural compatibility (correct field names, types, nesting) is what
//   these tests verify via `cue vet -c -t test ./...`.
// =============================================================================

// ── StatefulSet with container resources ──────────────────────────────────────

_testSSRes: #StatefulsetTransformer.#transform & {
	#component: _testStatefulSetComponentWithResources
	#context:   _testContext
}

// ── DaemonSet with container resources ───────────────────────────────────────

_testDSRes: #DaemonSetTransformer.#transform & {
	#component: _testDaemonSetComponentWithResources
	#context:   _testContext
}

// ── CronJob with container resources ─────────────────────────────────────────

_testCJRes: #CronJobTransformer.#transform & {
	#component: _testCronJobComponentWithResources
	#context:   _testContext
}

// ── Job with container resources ──────────────────────────────────────────────

_testJRes: #JobTransformer.#transform & {
	#component: _testJobComponentWithResources
	#context:   _testContext
}

// ── Deployment with string container resources ────────────────────────────────

_testDepRes: #DeploymentTransformer.#transform & {
	#component: _testComponentWithTraits
	#context:   _testContext
}

// ── Deployment with number container resources (normalization) ────────────────

_testDepNumRes: #DeploymentTransformer.#transform & {
	#component: _testComponentWithNumberResources
	#context:   _testContext
}
