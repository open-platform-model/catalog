package database

import (
	prim "opmodel.dev/core/v1alpha1/primitives@v1"
	component "opmodel.dev/core/v1alpha1/component@v1"
	mdb "opmodel.dev/mongodb_operator/v1alpha1/schemas/mongodbcommunity.mongodb.com/mongodbcommunity/v1@v1"
)

/////////////////////////////////////////////////////////////////
//// MongoDBCommunity Resource Definition
/////////////////////////////////////////////////////////////////

#MongoDBCommunityResource: prim.#Resource & {
	metadata: {
		modulePath:  "opmodel.dev/mongodb-operator/resources/database"
		version:     "v1"
		name:        "mongodb-community"
		description: "A MongoDB Community replica set (mongodbcommunity.mongodb.com/v1)"
		labels: {
			"resource.opmodel.dev/category": "database"
		}
	}

	#defaults: #MongoDBCommunityDefaults

	spec: close({mongodbCommunity: {
		metadata?: _#metadata
		spec?:     mdb.#MongoDBCommunitySpec
	}})
}

#MongoDBCommunity: component.#Component & {
	#resources: {(#MongoDBCommunityResource.metadata.fqn): #MongoDBCommunityResource}
}

#MongoDBCommunityDefaults: {
	metadata?: _#metadata
	spec?:     mdb.#MongoDBCommunitySpec
}

// _#metadata is a shared optional metadata struct for annotation passthrough.
_#metadata: {
	name?:      string
	namespace?: string
	labels?: {[string]: string}
	annotations?: {[string]: string}
}
