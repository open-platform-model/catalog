# mongodb-operator OPM resources

## Summary

OPM resource + transformer definitions for the [MongoDB Community Operator](https://github.com/mongodb/mongodb-kubernetes) `MongoDBCommunity` custom resource (`mongodbcommunity.mongodb.com/v1`).

Pure passthrough: the transformer emits a native `MongoDBCommunity` CR with OPM name prefix, namespace, and labels applied; `spec` is copied verbatim. Typed specs are vendored from the upstream CRD with `timoni mod vendor crd` — downstream consumers get full CUE field-level validation.

This module does **not** deploy the operator itself. Install the controller + RBAC + CRD separately (see `modules/mongodb_operator/` in this workspace).

## Contents

| Path | Description |
|---|---|
| `resources/database/mongodb_community.cue` | `#MongoDBCommunity` resource wrapper |
| `providers/kubernetes/` | `#Provider` + passthrough transformer |
| `schemas/mongodbcommunity.mongodb.com/mongodbcommunity/v1/types_gen.cue` | Timoni-generated CUE types from the upstream CRD. Do not edit by hand. |

## CRD Source

- **Upstream repo**: [mongodb/mongodb-kubernetes](https://github.com/mongodb/mongodb-kubernetes) (active; hosts the MongoDB Community Operator alongside the unified MongoDB Kubernetes Operator).
- **CRD file**: `config/crd/bases/mongodbcommunity.mongodb.com_mongodbcommunity.yaml`
- **Raw URL**: `https://raw.githubusercontent.com/mongodb/mongodb-kubernetes/master/config/crd/bases/mongodbcommunity.mongodb.com_mongodbcommunity.yaml`
- **CRD API group**: `mongodbcommunity.mongodb.com`

## Regenerating schemas

```bash
# 1. Download the CRD
curl -sSL -o /tmp/mongodb-community.yaml \
  https://raw.githubusercontent.com/mongodb/mongodb-kubernetes/master/config/crd/bases/mongodbcommunity.mongodb.com_mongodbcommunity.yaml

# 2. Generate CUE schemas (timoni writes to cue.mod/gen/...)
cd catalog/mongodb_operator/v1alpha1
timoni mod vendor crd -f /tmp/mongodb-community.yaml

# 3. Move generated files into the schemas/ tree
mv cue.mod/gen/mongodbcommunity.mongodb.com schemas/
rmdir cue.mod/gen

# 4. Validate
cue vet ./...
cue vet -t test ./...
```

When upstream ships a new CRD revision, re-run these steps.

## Links

- [MongoDB Community Kubernetes Operator](https://github.com/mongodb/mongodb-kubernetes/tree/master/mongodb-community-operator)
- [MongoDBCommunity CRD reference](https://www.mongodb.com/docs/kubernetes-operator/current/reference/k8s-operator-specification-fields/)
- [Timoni mod vendor crd docs](https://timoni.sh/cue-schemas/)
