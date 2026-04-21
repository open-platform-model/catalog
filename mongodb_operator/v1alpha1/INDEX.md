# v1alpha1 — Definition Index

CUE module: `opmodel.dev/mongodb_operator/v1alpha1@v1`

---

## Project Structure

```
+-- providers/
|   +-- kubernetes/
|       +-- transformers/
+-- resources/
|   +-- database/
+-- schemas/
    +-- mongodbcommunity.mongodb.com/
        +-- mongodbcommunity/
            +-- v1/
```

---

## Providers

### kubernetes

| Definition | File | Description |
|---|---|---|
| `#Provider` | `providers/kubernetes/provider.cue` | MongoDBOperatorKubernetesProvider transforms MongoDB Community Operator components to Kubernetes native resources (mongodbcommunity |

### kubernetes/transformers

| Definition | File | Description |
|---|---|---|
| `#MongoDBCommunityTransformer` | `providers/kubernetes/transformers/mongodb_community_transformer.cue` | #MongoDBCommunityTransformer passes native MongoDBCommunity resources through with OPM context applied (name prefix, namespace, labels) |
| `#TestCtx` | `providers/kubernetes/transformers/test_helpers.cue` | #TestCtx constructs a minimal concrete #TransformerContext for transformer tests |

---

## Resources

### database

| Definition | File | Description |
|---|---|---|
| `#MongoDBCommunity` | `resources/database/mongodb_community.cue` |  |
| `#MongoDBCommunityDefaults` | `resources/database/mongodb_community.cue` |  |
| `#MongoDBCommunityResource` | `resources/database/mongodb_community.cue` |  |

---

## Schemas

### mongodbcommunity.mongodb.com/mongodbcommunity/v1

| Definition | File | Description |
|---|---|---|
| `#MongoDBCommunity` | `schemas/mongodbcommunity.mongodb.com/mongodbcommunity/v1/types_gen.cue` | MongoDBCommunity is the Schema for the mongodbs API |
| `#MongoDBCommunitySpec` | `schemas/mongodbcommunity.mongodb.com/mongodbcommunity/v1/types_gen.cue` | MongoDBCommunitySpec defines the desired state of MongoDB |

---

