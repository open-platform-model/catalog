package platform_construct

// Pure-CUE matcher dispatch (014 D17 + D18 + 014/05-component-transformer-and-matcher.md).
//
// Two constructs:
//
//   - #SatisfiesComponent — predicate. Walks transformer match-keys against
//     a single component; returns _ok: true when every required label /
//     resource / trait is present (and labels match values). Mirrors the
//     `satisfiesComponent` pseudocode from 014/05.
//
//   - #PlatformRender — dispatch. For each (transformer, component) pair
//     where the predicate holds, unifies the transformer's #transform body
//     with the concrete release/component/context and projects `output`.
//     Returns #outputs keyed by "<transformerFqn>/<componentName>".
//
// What CUE can express: predicate decisions, the (transformer × component)
// fan-out via comprehension, the per-pair render via unification of
// #transform with concrete inputs. What it can't: ordering, deduplication
// across emitters, error aggregation, disk I/O — those stay Go-side.
//
// The dispatch deliberately filters to t.kind == "ComponentTransformer".
// 015's #ModuleTransformer (per-module fan-out) belongs to experiment 003.

#SatisfiesComponent: {
	transformer!: _
	component!:   _

	// Normalise optional fields to concrete maps. Direct subscript lookups
	// against these (e.g. `_cmpLabels[k]`) fail under `cue vet -c` when a
	// binding is empty — strict mode treats it as "undefined field <k>".
	// Workaround: never subscript; iterate-and-filter instead. Each "is k
	// present in cmp?" check becomes `[for ck, cv in cmp if ck == k {cv}]`
	// — a list comprehension that yields zero or one element, both of
	// which strict mode accepts.
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

	// "Missing" means: required key has no entry in the component, or the
	// component's entry has a different value (labels only — resources /
	// traits use map-set semantics, presence is enough).
	//
	// Implementation notes:
	//   - Built as a struct comprehension, then projected to a list. List
	//     addition (`[a] + [b]`) is deprecated in CUE 0.11+ in favour of
	//     `list.Concat`, which we can't reach (zero-stdlib experiment),
	//     so the union is expressed via two struct-comprehension passes
	//     into the same `_labelMismatches` map.
	//   - Subscript like `_cmpLabels[k]` is replaced by an iterate-and-
	//     filter list `_have = [for ck, cv in _cmpLabels if ck == k {cv}]`
	//     so strict mode never sees a direct map index.
	//   - The two label passes (missing-key vs wrong-value) are
	//     mutually-exclusive (gated by `len(_have)` polarity) so the same
	//     key cannot be emitted twice.
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

#PlatformRender: {
	#platform!:      _
	#moduleRelease!: _

	// Per-component context, materialised eagerly — one entry per component
	// in the release. A pattern-keyed `[cName=string]: ...` map deferred
	// the body's if-guard evaluation past the dispatch unification, leaving
	// `output` empty even with concrete inputs. Concrete keys force CUE to
	// resolve the context value at struct-construction time so the guards
	// in the fixture's `#transform` body fire when re-unified.
	_ctxFor: {
		for cName, _ in #moduleRelease.#module.#components {
			(cName): #TransformerContext & {
				release: {
					name:      #moduleRelease.name
					namespace: #moduleRelease.namespace
				}
				component: name: cName
			}
		}
	}

	// Pre-filter to component-scope transformers. 014 D17 makes this the
	// sole kind in scope at this layer; 015 adds #ModuleTransformer.
	_componentTransformers: {
		for fqn, t in #platform.#composedTransformers
		if t.kind == "ComponentTransformer" {
			(fqn): t
		}
	}

	// Dispatch — outer (transformer) × inner (component), guarded by the
	// satisfaction predicate. Each surviving pair unifies the transformer's
	// #transform body with concrete inputs and projects `output`. Key form
	// `"<transformerFqn>/<componentName>"` keeps every entry uniquely
	// addressable for both inspection and assertions.
	#outputs: {
		for tFqn, t in _componentTransformers
		if t.#transform != _|_
		for cName, cmp in #moduleRelease.#module.#components
		let _check = #SatisfiesComponent & {transformer: t, component: cmp}
		if _check._ok {
			"\(tFqn)/\(cName)": (t.#transform & {
				#moduleRelease: #moduleRelease
				#component:     cmp
				#context:       _ctxFor[cName]
			}).output
		}
	}
}
