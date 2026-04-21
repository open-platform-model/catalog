# clickhouse-operator OPM resources

## Summary

OPM resource + transformer definitions for the [Altinity ClickHouse Operator](https://github.com/Altinity/clickhouse-operator) custom resources.

Pure passthrough: transformers emit native CRs with OPM name prefix, namespace, and labels applied; `spec` is copied verbatim. Typed specs are vendored from upstream CRDs with `timoni mod vendor crd` — downstream consumers get full CUE field-level validation for deep `configuration` trees.

This module does **not** deploy the operator itself. Install the controller + RBAC + CRDs separately (see `modules/clickhouse_operator/` in this workspace).

## Contents

| Path | Description |
|---|---|
| `resources/database/clickhouse_installation.cue` | `#ClickHouseInstallation` resource wrapper |
| `resources/database/clickhouse_installation_template.cue` | `#ClickHouseInstallationTemplate` resource wrapper |
| `resources/database/clickhouse_keeper_installation.cue` | `#ClickHouseKeeperInstallation` resource wrapper |
| `resources/database/clickhouse_operator_configuration.cue` | `#ClickHouseOperatorConfiguration` resource wrapper |
| `providers/kubernetes/` | `#Provider` + 4 passthrough transformers |
| `schemas/clickhouse.altinity.com/*/v1/types_gen.cue` | Timoni-generated types for `clickhouse.altinity.com/v1` CRDs. Do not edit. |
| `schemas/clickhouse-keeper.altinity.com/*/v1/types_gen.cue` | Timoni-generated types for `clickhouse-keeper.altinity.com/v1` CRDs. Do not edit. |

## CRD Source

- **Upstream repo**: [Altinity/clickhouse-operator](https://github.com/Altinity/clickhouse-operator)
- **Bundle**: `deploy/operator/clickhouse-operator-install-bundle.yaml` (contains operator Deployment, RBAC, and 4 CRDs)
- **Raw URL**: `https://raw.githubusercontent.com/Altinity/clickhouse-operator/master/deploy/operator/clickhouse-operator-install-bundle.yaml`
- **CRD API groups**: `clickhouse.altinity.com`, `clickhouse-keeper.altinity.com`

## Regenerating schemas

The install bundle mixes Deployment, RBAC, and CRD manifests. Extract only the CRDs, then split them into one file per CRD because `timoni mod vendor crd` only processes the last document in a multi-doc YAML stream.

```bash
# 1. Download the bundle
curl -sSL -o /tmp/clickhouse-bundle.yaml \
  https://raw.githubusercontent.com/Altinity/clickhouse-operator/master/deploy/operator/clickhouse-operator-install-bundle.yaml

# 2. Extract CRDs and split
yq ea '[.] | .[] | select(.kind == "CustomResourceDefinition")' \
  /tmp/clickhouse-bundle.yaml > /tmp/clickhouse-crds.yaml
csplit -sz -f /tmp/chi- -b '%02d.yaml' /tmp/clickhouse-crds.yaml \
  '/^apiVersion: apiextensions/' '{*}'

# 3. Vendor each CRD
cd catalog/clickhouse_operator/v1alpha1
for f in /tmp/chi-01.yaml /tmp/chi-02.yaml /tmp/chi-03.yaml /tmp/chi-04.yaml; do
  timoni mod vendor crd -f "$f"
done

# 4. Relocate generated files
mv cue.mod/gen/clickhouse.altinity.com schemas/
mv cue.mod/gen/clickhouse-keeper.altinity.com schemas/
rmdir cue.mod/gen

# 5. Validate
cue vet ./...
cue vet -t test ./...
```

## Links

- [Altinity ClickHouse Operator documentation](https://github.com/Altinity/clickhouse-operator/tree/master/docs)
- [ClickHouseInstallation reference](https://github.com/Altinity/clickhouse-operator/blob/master/docs/custom_resource_explained.md)
- [Timoni mod vendor crd docs](https://timoni.sh/cue-schemas/)
