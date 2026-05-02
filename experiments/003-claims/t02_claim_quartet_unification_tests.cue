@if(test)

package claims

// T02 — CL-D6 quartet pattern + claim instance unification.
//
// Authoring `db: _managedDatabaseClaim & {#spec: {engine: ..., version: ...}}`
// unifies the consumer's spec value against the pinned #ManagedDatabaseSpec
// schema. Wrong engine values (not in the disjunction) become _|_.

_t02_db: _managedDatabaseClaim & {
	#spec: {
		engine:  "postgres"
		version: "16"
	}
}

t02_apiVersion: "opmodel.dev/opm/v1alpha2" & _t02_db.apiVersion
t02_kind:       "Claim" & _t02_db.kind
t02_fqn:        "opmodel.dev/opm/v1alpha2/claims/data/managed-database@v1" & _t02_db.metadata.fqn
t02_engine:     "postgres" & _t02_db.#spec.engine
t02_version:    "16" & _t02_db.#spec.version

// sizeGB defaults to 10 when omitted (CL-D6 quartet defaults).
t02_sizeGBDefault: 10 & _t02_db.#spec.sizeGB

// Direct instantiation with the wrapper's metadata works.
_t02_inst:      _managedDatabaseClaim
t02_modulePath: "opmodel.dev/opm/v1alpha2/claims/data" & _t02_inst.metadata.modulePath
t02_name:       "managed-database" & _t02_inst.metadata.name

// The hostname quartet pins #status with a required field.
_t02_host: _hostnameClaim & {
	#spec: name: "edge"
}
t02_hostnameSpecName: "edge" & _t02_host.#spec.name
