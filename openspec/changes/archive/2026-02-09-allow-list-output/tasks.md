## 1. Add annotation to plural resources

- [x] 1.1 Add `"transformer.opmodel.dev/list-output": true` to `#VolumesResource.metadata.annotations` in `v0/resources/storage/volume.cue`
- [x] 1.2 Add `"transformer.opmodel.dev/list-output": true` to `#ConfigMapsResource.metadata.annotations` in `v0/resources/config/configmap.cue`
- [x] 1.3 Add `"transformer.opmodel.dev/list-output": true` to `#SecretsResource.metadata.annotations` in `v0/resources/config/secret.cue`

## 2. Verify annotation propagation

- [x] 2.1 Run `task eval MODULE=examples` and confirm `transformer.opmodel.dev/list-output: true` appears in `metadata.annotations` of components that include `#Volumes`, `#ConfigMaps`, or `#Secrets`
- [x] 2.2 Confirm components without plural resources do not have the annotation in their `metadata.annotations`

## 3. Validation

- [x] 3.1 Run `task fmt` — all CUE files formatted
- [x] 3.2 Run `task vet` — all CUE files validate

## 4. Cleanup

- [x] 4.1 Mark the `allow-list-output` item as done in `TODO.md`
