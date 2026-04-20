# v1alpha1 — Definition Index

CUE module: `opmodel.dev/ch_vmm/v1alpha1@v1`

---

## Project Structure

```
+-- providers/
|   +-- kubernetes/
|       +-- transformers/
+-- resources/
|   +-- workload/
+-- schemas/
    +-- ch-vmm/
        +-- cloudhypervisor.quill.today/
            +-- virtualdisk/
            |   +-- v1beta1/
            +-- virtualdisksnapshot/
            |   +-- v1beta1/
            +-- virtualmachine/
            |   +-- v1beta1/
            +-- virtualmachinemigration/
            |   +-- v1beta1/
            +-- vmpool/
            |   +-- v1beta1/
            +-- vmrestorespec/
            |   +-- v1beta1/
            +-- vmrollback/
            |   +-- v1beta1/
            +-- vmset/
            |   +-- v1beta1/
            +-- vmsnapshot/
                +-- v1beta1/
```

---

## Providers

### kubernetes

| Definition | File | Description |
|---|---|---|
| `#Provider` | `providers/kubernetes/provider.cue` | ChVmmKubernetesProvider transforms ch-vmm components to Kubernetes native resources (cloudhypervisor |

### kubernetes/transformers

| Definition | File | Description |
|---|---|---|
| `#TestCtx` | `providers/kubernetes/transformers/test_helpers.cue` | #TestCtx constructs a minimal concrete #TransformerContext for transformer tests |
| `#VirtualDiskSnapshotTransformer` | `providers/kubernetes/transformers/virtual_disk_snapshot_transformer.cue` | #VirtualDiskSnapshotTransformer passes native ch-vmm VirtualDiskSnapshot resources through with OPM context applied (name prefix, namespace, labels) |
| `#VirtualDiskTransformer` | `providers/kubernetes/transformers/virtual_disk_transformer.cue` | #VirtualDiskTransformer passes native ch-vmm VirtualDisk resources through with OPM context applied (name prefix, namespace, labels) |
| `#VirtualMachineMigrationTransformer` | `providers/kubernetes/transformers/virtual_machine_migration_transformer.cue` | #VirtualMachineMigrationTransformer passes native ch-vmm VirtualMachineMigration resources through with OPM context applied (name prefix, namespace, labels) |
| `#VirtualMachineTransformer` | `providers/kubernetes/transformers/virtual_machine_transformer.cue` | #VirtualMachineTransformer passes native ch-vmm VirtualMachine resources through with OPM context applied (name prefix, namespace, labels) |
| `#VMPoolTransformer` | `providers/kubernetes/transformers/vm_pool_transformer.cue` | #VMPoolTransformer passes native ch-vmm VMPool resources through with OPM context applied (name prefix, namespace, labels) |
| `#VMRestoreSpecTransformer` | `providers/kubernetes/transformers/vm_restore_spec_transformer.cue` | #VMRestoreSpecTransformer passes native ch-vmm VMRestoreSpec resources through with OPM context applied (name prefix, namespace, labels) |
| `#VMRollbackTransformer` | `providers/kubernetes/transformers/vm_rollback_transformer.cue` | #VMRollbackTransformer passes native ch-vmm VMRollback resources through with OPM context applied (name prefix, namespace, labels) |
| `#VMSetTransformer` | `providers/kubernetes/transformers/vm_set_transformer.cue` | #VMSetTransformer passes native ch-vmm VMSet resources through with OPM context applied (name prefix, namespace, labels) |
| `#VMSnapShotTransformer` | `providers/kubernetes/transformers/vm_snapshot_transformer.cue` | #VMSnapShotTransformer passes native ch-vmm VMSnapShot resources through with OPM context applied (name prefix, namespace, labels) |

---

## Resources

### workload

| Definition | File | Description |
|---|---|---|
| `#VirtualDisk` | `resources/workload/virtual_disk.cue` |  |
| `#VirtualDiskDefaults` | `resources/workload/virtual_disk.cue` |  |
| `#VirtualDiskResource` | `resources/workload/virtual_disk.cue` |  |
| `#VirtualDiskSnapshot` | `resources/workload/virtual_disk_snapshot.cue` |  |
| `#VirtualDiskSnapshotDefaults` | `resources/workload/virtual_disk_snapshot.cue` |  |
| `#VirtualDiskSnapshotResource` | `resources/workload/virtual_disk_snapshot.cue` |  |
| `#VirtualMachine` | `resources/workload/virtual_machine.cue` |  |
| `#VirtualMachineDefaults` | `resources/workload/virtual_machine.cue` |  |
| `#VirtualMachineResource` | `resources/workload/virtual_machine.cue` |  |
| `#VirtualMachineMigration` | `resources/workload/virtual_machine_migration.cue` |  |
| `#VirtualMachineMigrationDefaults` | `resources/workload/virtual_machine_migration.cue` |  |
| `#VirtualMachineMigrationResource` | `resources/workload/virtual_machine_migration.cue` |  |
| `#VMPool` | `resources/workload/vm_pool.cue` |  |
| `#VMPoolDefaults` | `resources/workload/vm_pool.cue` |  |
| `#VMPoolResource` | `resources/workload/vm_pool.cue` |  |
| `#VMRestoreSpec` | `resources/workload/vm_restore_spec.cue` |  |
| `#VMRestoreSpecDefaults` | `resources/workload/vm_restore_spec.cue` |  |
| `#VMRestoreSpecResource` | `resources/workload/vm_restore_spec.cue` |  |
| `#VMRollback` | `resources/workload/vm_rollback.cue` |  |
| `#VMRollbackDefaults` | `resources/workload/vm_rollback.cue` |  |
| `#VMRollbackResource` | `resources/workload/vm_rollback.cue` |  |
| `#VMSet` | `resources/workload/vm_set.cue` |  |
| `#VMSetDefaults` | `resources/workload/vm_set.cue` |  |
| `#VMSetResource` | `resources/workload/vm_set.cue` |  |
| `#VMSnapShot` | `resources/workload/vm_snapshot.cue` |  |
| `#VMSnapShotDefaults` | `resources/workload/vm_snapshot.cue` |  |
| `#VMSnapShotResource` | `resources/workload/vm_snapshot.cue` |  |

---

## Schemas

### ch-vmm/cloudhypervisor.quill.today/virtualdisksnapshot/v1beta1

| Definition | File | Description |
|---|---|---|
| `#VirtualDiskSnapshot` | `schemas/ch-vmm/cloudhypervisor.quill.today/virtualdisksnapshot/v1beta1/types_gen.cue` | VirtualDiskSnapshot is the Schema for the virtualdisksnapshots API |
| `#VirtualDiskSnapshotSpec` | `schemas/ch-vmm/cloudhypervisor.quill.today/virtualdisksnapshot/v1beta1/types_gen.cue` | VirtualDiskSnapshotSpec defines the desired state of VirtualDiskSnapshot |

### ch-vmm/cloudhypervisor.quill.today/virtualdisk/v1beta1

| Definition | File | Description |
|---|---|---|
| `#VirtualDisk` | `schemas/ch-vmm/cloudhypervisor.quill.today/virtualdisk/v1beta1/types_gen.cue` | VirtualDisk is the Schema for the virtualdisks API |
| `#VirtualDiskSpec` | `schemas/ch-vmm/cloudhypervisor.quill.today/virtualdisk/v1beta1/types_gen.cue` | VirtualDiskSpec defines the desired state of VirtualDisk |

### ch-vmm/cloudhypervisor.quill.today/virtualmachinemigration/v1beta1

| Definition | File | Description |
|---|---|---|
| `#VirtualMachineMigration` | `schemas/ch-vmm/cloudhypervisor.quill.today/virtualmachinemigration/v1beta1/types_gen.cue` |  |
| `#VirtualMachineMigrationSpec` | `schemas/ch-vmm/cloudhypervisor.quill.today/virtualmachinemigration/v1beta1/types_gen.cue` |  |

### ch-vmm/cloudhypervisor.quill.today/virtualmachine/v1beta1

| Definition | File | Description |
|---|---|---|
| `#VirtualMachine` | `schemas/ch-vmm/cloudhypervisor.quill.today/virtualmachine/v1beta1/types_gen.cue` | VirtualMachine is the Schema for the virtualmachines API |
| `#VirtualMachineSpec` | `schemas/ch-vmm/cloudhypervisor.quill.today/virtualmachine/v1beta1/types_gen.cue` | VirtualMachineSpec defines the desired state of VirtualMachine |

### ch-vmm/cloudhypervisor.quill.today/vmpool/v1beta1

| Definition | File | Description |
|---|---|---|
| `#VMPool` | `schemas/ch-vmm/cloudhypervisor.quill.today/vmpool/v1beta1/types_gen.cue` |  |
| `#VMPoolSpec` | `schemas/ch-vmm/cloudhypervisor.quill.today/vmpool/v1beta1/types_gen.cue` | VMPoolSpec defines the desired state of VMPool |

### ch-vmm/cloudhypervisor.quill.today/vmrestorespec/v1beta1

| Definition | File | Description |
|---|---|---|
| `#VMRestoreSpec` | `schemas/ch-vmm/cloudhypervisor.quill.today/vmrestorespec/v1beta1/types_gen.cue` | VMRestoreSpec is the Schema for the vmrestorespecs API |
| `#VMRestoreSpecSpec` | `schemas/ch-vmm/cloudhypervisor.quill.today/vmrestorespec/v1beta1/types_gen.cue` | VMRestoreSpecSpec defines the desired state of VMRestoreSpec |

### ch-vmm/cloudhypervisor.quill.today/vmrollback/v1beta1

| Definition | File | Description |
|---|---|---|
| `#VMRollback` | `schemas/ch-vmm/cloudhypervisor.quill.today/vmrollback/v1beta1/types_gen.cue` | VMRollback is the Schema for the vmrollbacks API |
| `#VMRollbackSpec` | `schemas/ch-vmm/cloudhypervisor.quill.today/vmrollback/v1beta1/types_gen.cue` |  |

### ch-vmm/cloudhypervisor.quill.today/vmset/v1beta1

| Definition | File | Description |
|---|---|---|
| `#VMSet` | `schemas/ch-vmm/cloudhypervisor.quill.today/vmset/v1beta1/types_gen.cue` | VMSet is the Schema for the vmsets API |
| `#VMSetSpec` | `schemas/ch-vmm/cloudhypervisor.quill.today/vmset/v1beta1/types_gen.cue` | VMSetSpec defines the desired state of VMSet |

### ch-vmm/cloudhypervisor.quill.today/vmsnapshot/v1beta1

| Definition | File | Description |
|---|---|---|
| `#VMSnapShot` | `schemas/ch-vmm/cloudhypervisor.quill.today/vmsnapshot/v1beta1/types_gen.cue` | VMSnapShot is the Schema for the vmsnapshots API |
| `#VMSnapShotSpec` | `schemas/ch-vmm/cloudhypervisor.quill.today/vmsnapshot/v1beta1/types_gen.cue` | VMSnapShotSpec defines the desired state of VMSnapShot |

---

