## 1. Add annotation to VolumesResource

- [ ] 1.1 Add `"transformer.opmodel.dev/list-output": true` to `#VolumesResource.metadata.annotations` in `v0/resources/storage/volume.cue`

## 2. Verify annotation propagation

- [ ] 2.1 Run `task eval MODULE=examples` and confirm `transformer.opmodel.dev/list-output: true` appears in `metadata.annotations` of components that include `#Volumes`
- [ ] 2.2 Confirm components without `#Volumes` do not have the annotation in their `metadata.annotations`

## 3. Validation

- [ ] 3.1 Run `task fmt` — all CUE files formatted
- [ ] 3.2 Run `task vet` — all CUE files validate

## 4. Cleanup

- [ ] 4.1 Mark the `allow-list-output` item as done in `TODO.md`
