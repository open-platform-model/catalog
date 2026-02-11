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
- [ ] Look into changeing #TransformerContext.output.#component into #TransformerContext.output.component. Should work because it MUST be concrete when passed to the context.
- [ ] Look into changeing #TransformerContext.output.#context into #TransformerContext.output.context. Should work because it MUST be concrete when passed to the context.

## Bugfix

- [ ] Update the CLI kubernetes SDK to 1.34+
  - Fix warnings like "Warning: v1 ComponentStatus is deprecated in v1.19+" and "Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice" while we are at it. This is caused by the transformers output is of an older k8s version.

    ```bash
    ❯ opm mod delete --name Blog -n default --verbose
    2026/02/06 11:43:01 DEBU <output/log.go:33> resolved config path path=/var/home/emil/.opm/config.cue source=default
    2026/02/06 11:43:01 DEBU <output/log.go:33> bootstrap: extracted registry from config registry=localhost:5000 path=/var/home/emil/.opm/config.cue
    2026/02/06 11:43:01 DEBU <output/log.go:33> resolved registry registry=localhost:5000 source=env
    2026/02/06 11:43:01 DEBU <output/log.go:33> setting CUE_REGISTRY for config load registry=localhost:5000
    2026/02/06 11:43:01 DEBU <output/log.go:33> extracted provider from config name=kubernetes
    2026/02/06 11:43:01 DEBU <output/log.go:33> extracted providers from config count=1
    2026/02/06 11:43:01 DEBU <output/log.go:33> initializing CLI kubeconfig="" context="" namespace="" config="" output=yaml registry_flag="" resolved_registry=localhost:5000
    Delete all resources for module "Blog" in namespace "default"? [y/N]: y
    2026/02/06 11:43:03 INFO <output/log.go:38> deleting resources for module "Blog" in namespace "default"
    I0206 11:43:03.107650 1902817 warnings.go:107] "Warning: v1 ComponentStatus is deprecated in v1.19+"
    I0206 11:43:03.110144 1902817 warnings.go:107] "Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice"
    2026/02/06 11:43:13 WARN <output/log.go:43> deleting Endpoints/web: the server could not find the requested resource
    2026/02/06 11:43:13 INFO <output/log.go:38>   EndpointSlice/web-n5gh4 in default deleted
    2026/02/06 11:43:13 INFO <output/log.go:38>   DaemonSet/api in default deleted
    2026/02/06 11:43:13 INFO <output/log.go:38>   DaemonSet/web in default deleted
    2026/02/06 11:43:13 INFO <output/log.go:38>   Deployment/api in default deleted
    2026/02/06 11:43:14 INFO <output/log.go:38>   Deployment/web in default deleted
    2026/02/06 11:43:14 INFO <output/log.go:38>   StatefulSet/api in default deleted
    2026/02/06 11:43:14 INFO <output/log.go:38>   StatefulSet/web in default deleted
    2026/02/06 11:43:14 INFO <output/log.go:38>   Service/web in default deleted
    2026/02/06 11:43:14 WARN <output/log.go:43> 1 resource(s) had errors
    2026/02/06 11:43:14 ERRO <output/log.go:48> Endpoints/web in default: the server could not find the requested resource
    2026/02/06 11:43:14 INFO <output/log.go:38> delete complete: 8 resources deleted
    1 resource(s) failed to delete
    ```
