## 1. Shared Constants and Types

- [x] 1.1 Generate a UUID v4 to serve as the OPM namespace constant. Document it as immutable with a comment explaining its purpose and that it must match the CLI Go constant.
- [x] 1.2 Add `OPMNamespace` hidden definition to `v0/core/common.cue` with the generated UUID.
- [x] 1.3 Add `#UUIDType` regex constraint to `v0/core/common.cue`: `string & =~"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"`.

## 2. Module Identity

- [x] 2.1 Add `import "uuid"` to `v0/core/module.cue`.
- [x] 2.2 Add `uuid: #UUIDType & uuid.SHA1(OPMNamespace, "\(fqn):\(version)")` to `#Module.metadata`, after the `version` field.

## 3. Release Identity

- [x] 3.1 Add `import "uuid"` to `v0/core/module_release.cue`.
- [x] 3.2 Add `uuid: #UUIDType & uuid.SHA1(OPMNamespace, "\(#module.metadata.fqn):\(name):\(namespace)")` to `#ModuleRelease.metadata`, after the `version` field.

## 4. Verification

- [x] 4.1 Run `task eval` on the core module and verify `_testModule.metadata.identity` and `_testModuleRelease.metadata.identity` are populated with valid UUIDs.
- [x] 4.2 Verify determinism: evaluate twice and confirm identical identity values.
- [x] 4.3 Verify non-settable: temporarily add an explicit `uuid: "override"` to `_testModule`, confirm CUE produces a conflict error, then remove the override.
- [x] 4.4 Verify release identity is version-stable: create a temporary test with two releases referencing different module versions but same name/namespace, confirm identical release identities.

## 5. Downstream Validation

- [x] 5.1 Run `task fmt` on the core module — all CUE files formatted.
- [x] 5.2 Run `task vet` on the core module — all CUE files validate.
- [x] 5.3 Run `task vet` across the full catalog (`v0/`) — ensure no downstream breakage in resources, traits, providers, or examples that import core.
- [x] 5.4 Record the `_testModule.metadata.identity` and `_testModuleRelease.metadata.identity` values and the `OPMNamespace` UUID for the CLI companion change to use in cross-language tests.

## Cross-Language Test Values

| Constant | Value |
|----------|-------|
| `OPMNamespace` | `11bc6112-a6e8-4021-bec9-b3ad246f9466` |
| `_testModule.metadata.identity` | `8da1a802-97dd-5818-95a8-c47a02a5112f` |
| `_testModuleRelease.metadata.identity` | `d5d213f4-ae8e-54a1-82da-52a0b5b955de` |
