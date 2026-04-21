@if(test)

package transformers

// Test: minimal MongoDBCommunity replica set
_testMongoDBCommunityMinimal: (#MongoDBCommunityTransformer.#transform & {
	#component: {
		metadata: name: "metadata-db"
		spec: mongodbCommunity: {
			spec: {
				members: 3
				type:    "ReplicaSet"
				version: "6.0.5"
				security: {
					authentication: modes: ["SCRAM"]
				}
			}
		}
	}
	#context: (#TestCtx & {release: "hyperdx", namespace: "clickstack", component: "metadata-db"}).out
}).output & {
	apiVersion: "mongodbcommunity.mongodb.com/v1"
	kind:       "MongoDBCommunity"
	metadata: {
		name:      "hyperdx-metadata-db"
		namespace: "clickstack"
	}
	spec: {
		members: 3
		type:    "ReplicaSet"
		version: "6.0.5"
	}
}

// Test: annotations passthrough
_testMongoDBCommunityAnnotations: (#MongoDBCommunityTransformer.#transform & {
	#component: {
		metadata: name: "db"
		spec: mongodbCommunity: {
			metadata: annotations: {
				"backup.opmodel.dev/schedule": "0 2 * * *"
			}
			spec: {
				members: 1
				type:    "ReplicaSet"
				version: "6.0.5"
			}
		}
	}
	#context: (#TestCtx & {release: "rel", namespace: "ns", component: "db"}).out
}).output & {
	metadata: {
		name:      "rel-db"
		namespace: "ns"
		annotations: "backup.opmodel.dev/schedule": "0 2 * * *"
	}
}
