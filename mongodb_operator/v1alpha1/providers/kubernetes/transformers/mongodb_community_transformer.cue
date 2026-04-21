package transformers

import (
	transformer "opmodel.dev/core/v1alpha1/transformer@v1"
	res "opmodel.dev/mongodb_operator/v1alpha1/resources/database@v1"
)

// #MongoDBCommunityTransformer passes native MongoDBCommunity resources through
// with OPM context applied (name prefix, namespace, labels).
#MongoDBCommunityTransformer: transformer.#Transformer & {
	metadata: {
		modulePath:  "opmodel.dev/mongodb-operator/providers/kubernetes/transformers"
		version:     "v1"
		name:        "mongodb-community-transformer"
		description: "Passes native MongoDBCommunity resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "database"
			"core.opmodel.dev/resource-type":     "mongodb-community"
		}
	}

	requiredLabels: {}
	requiredResources: {(res.#MongoDBCommunityResource.metadata.fqn): res.#MongoDBCommunityResource}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   transformer.#TransformerContext

		_mdb:  #component.spec.mongodbCommunity
		_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

		output: {
			apiVersion: "mongodbcommunity.mongodb.com/v1"
			kind:       "MongoDBCommunity"
			metadata: {
				name:      _name
				namespace: #context.#moduleReleaseMetadata.namespace
				labels:    #context.labels
				if _mdb.metadata != _|_ {
					if _mdb.metadata.annotations != _|_ {
						annotations: _mdb.metadata.annotations
					}
				}
			}
			if _mdb.spec != _|_ {
				spec: _mdb.spec
			}
		}
	}
}
