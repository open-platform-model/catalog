@if(test)

package claims

// T03 — DEF-D2: #defines.claims map key is bound to value.metadata.fqn.
//
// _opmCoreModule.#defines.claims registers _managedDatabaseClaim under its
// own FQN key. Reading the entry back must echo the same FQN.

_t03_claims: _opmCoreModule.#defines.claims

t03_managedDbPresent: true & (_t03_claims["opmodel.dev/opm/v1alpha2/claims/data/managed-database@v1"] != _|_)
t03_managedDbFqn:     "opmodel.dev/opm/v1alpha2/claims/data/managed-database@v1" & _t03_claims["opmodel.dev/opm/v1alpha2/claims/data/managed-database@v1"].metadata.fqn

// Trait + resource binding (014's #defines, validated alongside).
t03_containerFqn: "opmodel.dev/opm/v1alpha2/resources/workload/container@v1" & _opmCoreModule.#defines.resources["opmodel.dev/opm/v1alpha2/resources/workload/container@v1"].metadata.fqn
t03_exposeFqn:    "opmodel.dev/opm/v1alpha2/traits/network/expose@v1" & _opmCoreModule.#defines.traits["opmodel.dev/opm/v1alpha2/traits/network/expose@v1"].metadata.fqn

// Transformer publication via union (TR-D5 — 015 widens to ComponentTransformer
// | ModuleTransformer). _k8upModule registers a #ModuleTransformer.
t03_k8upTransformerKind: "ModuleTransformer" & _k8upModule.#defines.transformers["opmodel.dev/k8up/v1alpha2/transformers/backup-schedule-transformer@v1"].kind
