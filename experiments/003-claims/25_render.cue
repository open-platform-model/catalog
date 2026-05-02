package claims

// Pure-CUE render pipeline (014 D17 + 014/05 + 015 TR-D5 + 015/12).
//
// Four phases in a single CUE evaluation. Two-stage dispatch breaks the
// writeback / reader cycle (Risk R1 in the experiment plan):
//
//   Phase 1 (dispatch BASE) — invoke each fired transformer's #transform
//                              against the as-authored #moduleRelease.
//                              #statusWrites must NOT read #status (depth-1
//                              contract); it depends only on #spec /
//                              #context / fixed inputs.
//
//   Phase 2 (project writebacks) — walk every base fire's #statusWrites
//                                   and resolve the consumer's claim id by
//                                   FQN-equality against the matched
//                                   #claims.<id>.metadata.fqn.
//
//   Phase 3 (inject via unification) — define #moduleReleaseWithStatus as
//                                       #moduleRelease & {patch}, where
//                                       patch is the writeback projection
//                                       reshaped into the right paths.
//
//   Phase 4 (dispatch FINAL) — re-invoke transformers against
//                               #moduleReleaseWithStatus. Reader bodies
//                               see populated #status. Outputs ship.
//
// Notes from initial evaluation:
//   - The subscript `_ctxFor[cName]` was rejected as "invalid index cName
//     (invalid type _)" because #moduleRelease is typed `_`. Workaround:
//     inline #TransformerContext construction inside each per-fire body —
//     cName interpolates as a string field, no subscript on a `_`-typed
//     map.
//   - `cmp.#claims` similarly avoided in cross-phase wiring; each fire
//     stores its own `_claims` snapshot for Phase 2 to read directly.
//   - CUE rejects fields whose NAME matches a comprehension's loop variable:
//       for tFqn, t in m { "\(tFqn)": { tFqn: tFqn } }
//     fails with "field not allowed". Workaround: rename the storage
//     fields (we use _tfqn / _cname). To be lifted to enhancement docs.

#SatisfiesComponent: {
	transformer!: _
	component!:   _

	_reqLabels: {
		if transformer.requiredLabels != _|_
		for k, v in transformer.requiredLabels {(k): v}
	}
	_reqResources: {
		if transformer.requiredResources != _|_
		for k, v in transformer.requiredResources {(k): v}
	}
	_reqTraits: {
		if transformer.requiredTraits != _|_
		for k, v in transformer.requiredTraits {(k): v}
	}

	_cmpLabels: {
		if component.metadata.labels != _|_
		for k, v in component.metadata.labels {(k): v}
	}
	_cmpResources: {
		if component.#resources != _|_
		for k, v in component.#resources {(k): v}
	}
	_cmpTraits: {
		if component.#traits != _|_
		for k, v in component.#traits {(k): v}
	}

	_labelMismatches: {
		for k, v in _reqLabels
		let _have = [for ck, cv in _cmpLabels if ck == k {cv}]
		if len(_have) == 0 {
			(k): "missing"
		}
		for k, v in _reqLabels
		let _have = [for ck, cv in _cmpLabels if ck == k {cv}]
		if len(_have) > 0
		if _have[0] != v {
			(k): "wrong"
		}
	}
	_missingLabels: [for k, _ in _labelMismatches {k}]

	_missingResources: [
		for fqn, _ in _reqResources
		let _have = [for cfqn, _ in _cmpResources if cfqn == fqn {true}]
		if len(_have) == 0 {fqn},
	]
	_missingTraits: [
		for fqn, _ in _reqTraits
		let _have = [for cfqn, _ in _cmpTraits if cfqn == fqn {true}]
		if len(_have) == 0 {fqn},
	]

	_ok: bool
	_ok: (len(_missingLabels) + len(_missingResources) + len(_missingTraits)) == 0
}

// #SatisfiesModule — module-scope label + claim-FQN match.
#SatisfiesModule: {
	transformer!:   _
	moduleRelease!: _

	_reqLabels: {
		if transformer.requiredLabels != _|_
		for k, v in transformer.requiredLabels {(k): v}
	}
	_modLabels: {
		if moduleRelease.#module.metadata.labels != _|_
		for k, v in moduleRelease.#module.metadata.labels {(k): v}
	}
	_missingLabels: [
		for k, v in _reqLabels
		let _have = [for ck, cv in _modLabels if ck == k {cv}]
		if len(_have) == 0 || _have[0] != v {k},
	]

	_modClaimFqns: {
		if moduleRelease.#module.#claims != _|_
		for _, c in moduleRelease.#module.#claims {
			(c.metadata.fqn): _
		}
	}
	_missingClaims: [
		if transformer.requiredClaims != _|_
		for fqn, _ in transformer.requiredClaims
		let _have = [for k, _ in _modClaimFqns if k == fqn {true}]
		if len(_have) == 0 {fqn},
	]

	_ok: bool
	_ok: (len(_missingLabels) + len(_missingClaims)) == 0
}

// #AnyComponentMatches — pre-fire gate for #ModuleTransformer.requiresComponents
// (TR-D7). Conjunction within a component, OR across components.
#AnyComponentMatches: {
	moduleRelease!: _
	rc!:            _

	_matches: [
		if moduleRelease.#module.#components != _|_
		for cName, cmp in moduleRelease.#module.#components
		let _resMissing = [
			if rc.resources != _|_
			for fqn, _ in rc.resources
			let _have = [
				if cmp.#resources != _|_
				for cfqn, _ in cmp.#resources if cfqn == fqn {true},
			]
			if len(_have) == 0 {fqn},
		]
		let _trtMissing = [
			if rc.traits != _|_
			for fqn, _ in rc.traits
			let _have = [
				if cmp.#traits != _|_
				for cfqn, _ in cmp.#traits if cfqn == fqn {true},
			]
			if len(_have) == 0 {fqn},
		]
		let _clmFqns = {
			if cmp.#claims != _|_
			for _, c in cmp.#claims {(c.metadata.fqn): _}
		}
		let _clmMissing = [
			if rc.claims != _|_
			for fqn, _ in rc.claims
			let _have = [for k, _ in _clmFqns if k == fqn {true}]
			if len(_have) == 0 {fqn},
		]
		if (len(_resMissing) + len(_trtMissing) + len(_clmMissing)) == 0 {cName},
	]
	_ok: len(_matches) > 0
}

// #PlatformRender — full pipeline.
//
// Naming gotcha: do NOT write `#moduleRelease: #moduleRelease` inside the
// dispatched `t.#transform & {...}` body. The RHS resolves to the inner
// field (self-reference), not the outer scope's value, leaving the input
// open. Capture the outer scope via let-bindings (_release, _platform)
// and reference those in the unification.
#PlatformRender: {
	#platform!:      _
	#moduleRelease!: _

	let _release = #moduleRelease
	let _platform = #platform

	_componentTransformers: {
		for fqn, t in _platform.#composedTransformers
		if t.kind == "ComponentTransformer" {
			(fqn): t
		}
	}
	_moduleTransformers: {
		for fqn, t in _platform.#composedTransformers
		if t.kind == "ModuleTransformer" {
			(fqn): t
		}
	}

	// ============================================================
	// PHASE 1 — dispatch BASE.
	// ============================================================

	_componentFiresBase: {
		for tFqn, t in _componentTransformers
		if t.#transform != _|_
		for cName, cmp in #moduleRelease.#module.#components
		let _check = #SatisfiesComponent & {transformer: t, component: cmp}
		if _check._ok
		let _claimMissing = [
			if t.requiredClaims != _|_
			for fqn, _ in t.requiredClaims
			let _have = [
				if cmp.#claims != _|_
				for _, c in cmp.#claims if c.metadata.fqn == fqn {true},
			]
			if len(_have) == 0 {fqn},
		]
		if len(_claimMissing) == 0 {
			"\(tFqn)/\(cName)": {
				_tfqn:       tFqn
				_cname:      cName
				transformer: t
				// Snapshot of the component's #claims for Phase 2 use
				// (avoids cross-phase subscript on #moduleRelease).
				_claims: {
					if cmp.#claims != _|_
					for k, v in cmp.#claims {(k): v}
				}
				_result: t.#transform & {
					#moduleRelease: _release
					#component:     cmp

					// Inline context — interpolation, no subscript on a
					// `_`-typed map. Mirrors 002's eager-context pattern.
					#context: #TransformerContext & {
						release: name:      _release.name
						release: namespace: _release.namespace
						component: name:    cName
					}
				}
			}
		}
	}

	_moduleFiresBase: {
		for tFqn, t in _moduleTransformers
		if t.#transform != _|_
		let _sat = #SatisfiesModule & {transformer: t, moduleRelease: #moduleRelease}
		if _sat._ok
		let _gateNeeded = t.requiresComponents != _|_
		let _gate = #AnyComponentMatches & {
			moduleRelease: #moduleRelease
			rc:            t.requiresComponents
		}
		if !_gateNeeded || _gate._ok {
			(tFqn): {
				_tfqn:       tFqn
				transformer: t
				_result: t.#transform & {
					#moduleRelease: _release
					#context: #TransformerContext & {
						release: name:      _release.name
						release: namespace: _release.namespace
					}
				}
			}
		}
	}

	// ============================================================
	// PHASE 2 — writebacks from BASE.
	// ============================================================

	_componentWritebacks: {
		for fireKey, fire in _componentFiresBase
		if fire._result.#statusWrites != _|_
		if fire.transformer.requiredClaims != _|_
		for fqn, _ in fire.transformer.requiredClaims
		for cId, claim in fire._claims
		if claim.metadata.fqn == fqn
		for swId, swVal in fire._result.#statusWrites
		if swId == cId {
			(fire._cname): (cId): swVal
		}
	}

	_moduleWritebacks: {
		for tFqn, fire in _moduleFiresBase
		if fire._result.#statusWrites != _|_
		if fire.transformer.requiredClaims != _|_
		if #moduleRelease.#module.#claims != _|_
		for fqn, _ in fire.transformer.requiredClaims
		for cId, claim in #moduleRelease.#module.#claims
		if claim.metadata.fqn == fqn
		for swId, swVal in fire._result.#statusWrites
		if swId == cId {
			(cId): swVal
		}
	}

	// ============================================================
	// PHASE 3 — inject via unification.
	// ============================================================

	#moduleReleaseWithStatus: #moduleRelease & {
		#module: {
			#claims: {
				for cId, st in _moduleWritebacks {
					(cId): #status: st
				}
			}
			#components: {
				for cName, perComp in _componentWritebacks {
					(cName): #claims: {
						for cId, st in perComp {
							(cId): #status: st
						}
					}
				}
			}
		}
	}

	// ============================================================
	// PHASE 4 — final dispatch against #moduleReleaseWithStatus.
	// ============================================================

	_componentFires: {
		for tFqn, t in _componentTransformers
		if t.#transform != _|_
		for cName, cmp in #moduleReleaseWithStatus.#module.#components
		let _check = #SatisfiesComponent & {transformer: t, component: cmp}
		if _check._ok
		let _claimMissing = [
			if t.requiredClaims != _|_
			for fqn, _ in t.requiredClaims
			let _have = [
				if cmp.#claims != _|_
				for _, c in cmp.#claims if c.metadata.fqn == fqn {true},
			]
			if len(_have) == 0 {fqn},
		]
		if len(_claimMissing) == 0 {
			"\(tFqn)/\(cName)": {
				_tfqn:       tFqn
				_cname:      cName
				transformer: t
				_result: t.#transform & {
					#moduleRelease: #moduleReleaseWithStatus
					#component:     cmp
					#context: #TransformerContext & {
						release: name:      #moduleRelease.name
						release: namespace: #moduleRelease.namespace
						component: name:    cName
					}
				}
			}
		}
	}

	_moduleFires: {
		for tFqn, t in _moduleTransformers
		if t.#transform != _|_
		let _sat = #SatisfiesModule & {transformer: t, moduleRelease: #moduleReleaseWithStatus}
		if _sat._ok
		let _gateNeeded = t.requiresComponents != _|_
		let _gate = #AnyComponentMatches & {
			moduleRelease: #moduleReleaseWithStatus
			rc:            t.requiresComponents
		}
		if !_gateNeeded || _gate._ok {
			(tFqn): {
				_tfqn:       tFqn
				transformer: t
				_result: t.#transform & {
					#moduleRelease: #moduleReleaseWithStatus
					#context: #TransformerContext & {
						release: name:      _release.name
						release: namespace: _release.namespace
					}
				}
			}
		}
	}

	// ============================================================
	// Outputs + diagnostics.
	// ============================================================

	#outputs: {
		for fireKey, fire in _componentFires
		if fire._result.output != _|_ {
			(fireKey): fire._result.output
		}
		for tFqn, fire in _moduleFires
		if fire._result.output != _|_ {
			(tFqn): fire._result.output
		}
	}

	#status: {
		componentFires: [for k, _ in _componentFires {k}]
		moduleFires: [for k, _ in _moduleFires {k}]
		injectedComponent: _componentWritebacks
		injectedModule:    _moduleWritebacks
	}
}
