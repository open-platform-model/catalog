# v1alpha1 — Definition Index

CUE module: `opmodel.dev/clickhouse_operator/v1alpha1@v1`

---

## Project Structure

```
+-- providers/
|   +-- kubernetes/
|       +-- transformers/
+-- resources/
|   +-- database/
+-- schemas/
    +-- clickhouse.altinity.com/
    |   +-- clickhouseinstallation/
    |   |   +-- v1/
    |   +-- clickhouseinstallationtemplate/
    |   |   +-- v1/
    |   +-- clickhouseoperatorconfiguration/
    |       +-- v1/
    +-- clickhouse-keeper.altinity.com/
        +-- clickhousekeeperinstallation/
            +-- v1/
```

---

## Providers

### kubernetes

| Definition | File | Description |
|---|---|---|
| `#Provider` | `providers/kubernetes/provider.cue` | ClickHouseOperatorKubernetesProvider transforms ClickHouse operator components to Kubernetes native resources (Altinity CRs — pure passthrough with OPM context applied) |

### kubernetes/transformers

| Definition | File | Description |
|---|---|---|
| `#ClickHouseInstallationTemplateTransformer` | `providers/kubernetes/transformers/clickhouse_installation_template_transformer.cue` | #ClickHouseInstallationTemplateTransformer passes ClickHouseInstallationTemplate resources through with OPM context applied (name prefix, namespace, labels) |
| `#ClickHouseInstallationTransformer` | `providers/kubernetes/transformers/clickhouse_installation_transformer.cue` | #ClickHouseInstallationTransformer passes native ClickHouseInstallation resources through with OPM context applied (name prefix, namespace, labels) |
| `#ClickHouseKeeperInstallationTransformer` | `providers/kubernetes/transformers/clickhouse_keeper_installation_transformer.cue` | #ClickHouseKeeperInstallationTransformer passes ClickHouseKeeperInstallation resources through with OPM context applied (name prefix, namespace, labels) |
| `#ClickHouseOperatorConfigurationTransformer` | `providers/kubernetes/transformers/clickhouse_operator_configuration_transformer.cue` | #ClickHouseOperatorConfigurationTransformer passes ClickHouseOperatorConfiguration resources through with OPM context applied (name prefix, namespace, labels) |
| `#TestCtx` | `providers/kubernetes/transformers/test_helpers.cue` | #TestCtx constructs a minimal concrete #TransformerContext for transformer tests |

---

## Resources

### database

| Definition | File | Description |
|---|---|---|
| `#ClickHouseInstallation` | `resources/database/clickhouse_installation.cue` |  |
| `#ClickHouseInstallationDefaults` | `resources/database/clickhouse_installation.cue` |  |
| `#ClickHouseInstallationResource` | `resources/database/clickhouse_installation.cue` |  |
| `#ClickHouseInstallationTemplate` | `resources/database/clickhouse_installation_template.cue` |  |
| `#ClickHouseInstallationTemplateDefaults` | `resources/database/clickhouse_installation_template.cue` |  |
| `#ClickHouseInstallationTemplateResource` | `resources/database/clickhouse_installation_template.cue` |  |
| `#ClickHouseKeeperInstallation` | `resources/database/clickhouse_keeper_installation.cue` |  |
| `#ClickHouseKeeperInstallationDefaults` | `resources/database/clickhouse_keeper_installation.cue` |  |
| `#ClickHouseKeeperInstallationResource` | `resources/database/clickhouse_keeper_installation.cue` |  |
| `#ClickHouseOperatorConfiguration` | `resources/database/clickhouse_operator_configuration.cue` |  |
| `#ClickHouseOperatorConfigurationDefaults` | `resources/database/clickhouse_operator_configuration.cue` |  |
| `#ClickHouseOperatorConfigurationResource` | `resources/database/clickhouse_operator_configuration.cue` |  |

---

## Schemas

### clickhouse.altinity.com/clickhouseinstallationtemplate/v1

| Definition | File | Description |
|---|---|---|
| `#ClickHouseInstallationTemplate` | `schemas/clickhouse.altinity.com/clickhouseinstallationtemplate/v1/types_gen.cue` | define a set of Kubernetes resources (StatefulSet, PVC, Service, ConfigMap) which describe behavior one or more clusters |
| `#ClickHouseInstallationTemplateSpec` | `schemas/clickhouse.altinity.com/clickhouseinstallationtemplate/v1/types_gen.cue` | Specification of the desired behavior of one or more ClickHouse clusters More info: https://github |

### clickhouse.altinity.com/clickhouseinstallation/v1

| Definition | File | Description |
|---|---|---|
| `#ClickHouseInstallation` | `schemas/clickhouse.altinity.com/clickhouseinstallation/v1/types_gen.cue` | define a set of Kubernetes resources (StatefulSet, PVC, Service, ConfigMap) which describe behavior one or more clusters |
| `#ClickHouseInstallationSpec` | `schemas/clickhouse.altinity.com/clickhouseinstallation/v1/types_gen.cue` | Specification of the desired behavior of one or more ClickHouse clusters More info: https://github |

### clickhouse.altinity.com/clickhouseoperatorconfiguration/v1

| Definition | File | Description |
|---|---|---|
| `#ClickHouseOperatorConfiguration` | `schemas/clickhouse.altinity.com/clickhouseoperatorconfiguration/v1/types_gen.cue` | allows customize `clickhouse-operator` settings, need restart clickhouse-operator pod after adding, more details https://github |
| `#ClickHouseOperatorConfigurationSpec` | `schemas/clickhouse.altinity.com/clickhouseoperatorconfiguration/v1/types_gen.cue` | Allows to define settings of the clickhouse-operator |

### clickhouse-keeper.altinity.com/clickhousekeeperinstallation/v1

| Definition | File | Description |
|---|---|---|
| `#ClickHouseKeeperInstallation` | `schemas/clickhouse-keeper.altinity.com/clickhousekeeperinstallation/v1/types_gen.cue` | define a set of Kubernetes resources (StatefulSet, PVC, Service, ConfigMap) which describe behavior one or more clusters |
| `#ClickHouseKeeperInstallationSpec` | `schemas/clickhouse-keeper.altinity.com/clickhousekeeperinstallation/v1/types_gen.cue` | Specification of the desired behavior of one or more ClickHouse clusters More info: https://github |

---

