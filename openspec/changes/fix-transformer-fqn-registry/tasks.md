## 1. Core Schema — Constrain TransformerMap Keys

- [x] 1.1 Update `#TransformerMap` in `v0/core/transformer.cue` from `[string]: #Transformer` to `[#FQNType]: #Transformer`
- [x] 1.2 Run `task vet MODULE=core` in `v0/core` to verify the schema change validates

## 2. Standardize Transformer apiVersion Values

- [x] 2.1 Update `v0/providers/kubernetes/transformers/deployment_transformer.cue` — change `apiVersion: "transformer.opmodel.dev/workload@v1"` to `apiVersion: "opmodel.dev/providers/kubernetes/transformers@v0"`
- [x] 2.2 Update `v0/providers/kubernetes/transformers/daemonset_transformer.cue` — change `apiVersion: "transformer.opmodel.dev/workload@v1"` to `apiVersion: "opmodel.dev/providers/kubernetes/transformers@v0"`

## 3. Replace Hand-Written Registry Keys with Computed References

- [x] 3.1 Update `v0/providers/kubernetes/provider.cue` — replace all seven hand-written FQN string keys with parenthesized computed references using `(k8s_transformers.#<Name>.metadata.fqn): k8s_transformers.#<Name>`

## 4. Validation

- [x] 4.1 Run `task fmt` across all modules
- [x] 4.2 Run `task vet` across all modules to verify all definitions validate
- [x] 4.3 Run `task eval` across all modules to verify all definitions evaluate without errors
