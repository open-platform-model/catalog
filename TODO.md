# TODO

## Features

- [ ] Integrate the upstream Kubernetes schemas into the transformers, making sure the output is always correct
  - Make sure to pin against a specific version (e.g. v1.34) and force the transformers to comply with that version.
- [ ] Add #Policy into the workflow. This means adding it to #Modules, #ModuleReleases, #Transformers.
- [ ] Add support for immuatble ConfigMaps and Secrets. The immutable field will force the resource to be regenerated when a change is detected, working the same as a configMapGenerator or secretGenerator in kustomize.
  - Question: How do we prevent users from changing the field "immutable: true" to false?
- [x] Add `transformer.opmodel.dev/list-output` annotation to plural resources (#VolumesResource, #ConfigMapsResource, #SecretsResource). Propagates to #Component via existing annotation inheritance.
  - change: allow-list-output (implemented as annotation instead of top-level field per design decision)
  - sibling change in CLI: allow-list-output

## Investigations

- [ ] Look into the possibility to have support for different versions of Kubernetes and its APIs and how to support multiple versions.
- [ ] Investigate how to include a "well-known" platform context into a #Module. Something developers can reference but is only concrete at deployment time.
