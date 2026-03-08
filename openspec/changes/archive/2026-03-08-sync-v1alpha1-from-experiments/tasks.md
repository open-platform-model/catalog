## 1. Core Package Restructuring

- [x] 1.1 Delete all existing files in `v1alpha1/core/` (flat `.cue` files and `out.cue`)
- [x] 1.2 Copy `../cli/experiments/factory/v1alpha1/core/types/types.cue` → `v1alpha1/core/types/types.cue`
- [x] 1.3 Copy `../cli/experiments/factory/v1alpha1/core/primitives/` (resource.cue, trait.cue, blueprint.cue, policy_rule.cue) → `v1alpha1/core/primitives/`
- [x] 1.4 Copy `../cli/experiments/factory/v1alpha1/core/component/component.cue` → `v1alpha1/core/component/`
- [x] 1.5 Copy `../cli/experiments/factory/v1alpha1/core/module/module.cue` → `v1alpha1/core/module/`
- [x] 1.6 Copy `../cli/experiments/factory/v1alpha1/core/modulerelease/module_release.cue` → `v1alpha1/core/modulerelease/`
- [x] 1.7 Copy `../cli/experiments/factory/v1alpha1/core/bundle/bundle.cue` → `v1alpha1/core/bundle/`
- [x] 1.8 Copy `../cli/experiments/factory/v1alpha1/core/bundlerelease/bundle_release.cue` → `v1alpha1/core/bundlerelease/` (NEW)
- [x] 1.9 Copy `../cli/experiments/factory/v1alpha1/core/provider/provider.cue` → `v1alpha1/core/provider/`
- [x] 1.10 Copy `../cli/experiments/factory/v1alpha1/core/transformer/transformer.cue` → `v1alpha1/core/transformer/`
- [x] 1.11 Copy `../cli/experiments/factory/v1alpha1/core/policy/policy.cue` → `v1alpha1/core/policy/`
- [x] 1.12 Copy `../cli/experiments/factory/v1alpha1/core/helpers/autosecrets.cue` → `v1alpha1/core/helpers/` (NEW)
- [x] 1.13 Copy `../cli/experiments/factory/v1alpha1/core/matcher/matcher.cue` → `v1alpha1/core/matcher/` (NEW)

## 2. Resources (Import Path Updates)

- [x] 2.1 Copy `../cli/experiments/factory/v1alpha1/resources/workload/container.cue` → `v1alpha1/resources/workload/container.cue`
- [x] 2.2 Copy `../cli/experiments/factory/v1alpha1/resources/config/configmap.cue` → `v1alpha1/resources/config/configmap.cue`
- [x] 2.3 Copy `../cli/experiments/factory/v1alpha1/resources/config/secret.cue` → `v1alpha1/resources/config/secret.cue`
- [x] 2.4 Copy `../cli/experiments/factory/v1alpha1/resources/storage/volume.cue` → `v1alpha1/resources/storage/volume.cue`
- [x] 2.5 Copy `../cli/experiments/factory/v1alpha1/resources/extension/crd.cue` → `v1alpha1/resources/extension/crd.cue`
- [x] 2.6 Copy `../cli/experiments/factory/v1alpha1/resources/extension/crd_tests.cue` → `v1alpha1/resources/extension/crd_tests.cue`
- [x] 2.7 Copy `../cli/experiments/factory/v1alpha1/resources/security/service_account.cue` → `v1alpha1/resources/security/service_account.cue`
- [x] 2.8 Copy `../cli/experiments/factory/v1alpha1/resources/security/role.cue` → `v1alpha1/resources/security/role.cue`

## 3. Traits (Import Path Updates)

- [x] 3.1 Copy all `../cli/experiments/factory/v1alpha1/traits/network/` files (expose, http_route, grpc_route, tcp_route) → `v1alpha1/traits/network/`
- [x] 3.2 Copy all `../cli/experiments/factory/v1alpha1/traits/security/` files (security_context, workload_identity, encryption) → `v1alpha1/traits/security/`
- [x] 3.3 Copy all `../cli/experiments/factory/v1alpha1/traits/workload/` files (scaling, sizing, update_strategy, placement, restart_policy, init_containers, sidecar_containers, disruption_budget, graceful_shutdown, job_config, cron_job_config) → `v1alpha1/traits/workload/`

## 4. Blueprints (Import Path Updates)

- [x] 4.1 Copy all `../cli/experiments/factory/v1alpha1/blueprints/workload/` files (stateless, stateful, daemon, task, scheduled_task) → `v1alpha1/blueprints/workload/`
- [x] 4.2 Copy `../cli/experiments/factory/v1alpha1/blueprints/data/simple_database.cue` → `v1alpha1/blueprints/data/simple_database.cue`

## 5. Providers & Transformers (Import + Release-Prefix Logic)

- [x] 5.1 Copy `../cli/experiments/factory/v1alpha1/providers/kubernetes/provider.cue` → `v1alpha1/providers/kubernetes/provider.cue`
- [x] 5.2 Copy `../cli/experiments/factory/v1alpha1/providers/kubernetes/transformers/container_helpers.cue` → `v1alpha1/providers/kubernetes/transformers/` (includes #releasePrefix)
- [x] 5.3 Copy `../cli/experiments/factory/v1alpha1/providers/kubernetes/transformers/sa_helpers.cue` → `v1alpha1/providers/kubernetes/transformers/`
- [x] 5.4 Copy `../cli/experiments/factory/v1alpha1/providers/kubernetes/transformers/deployment_transformer.cue` → `v1alpha1/providers/kubernetes/transformers/`
- [x] 5.5 Copy `../cli/experiments/factory/v1alpha1/providers/kubernetes/transformers/statefulset_transformer.cue` → `v1alpha1/providers/kubernetes/transformers/`
- [x] 5.6 Copy `../cli/experiments/factory/v1alpha1/providers/kubernetes/transformers/daemonset_transformer.cue` → `v1alpha1/providers/kubernetes/transformers/`
- [x] 5.7 Copy `../cli/experiments/factory/v1alpha1/providers/kubernetes/transformers/job_transformer.cue` → `v1alpha1/providers/kubernetes/transformers/`
- [x] 5.8 Copy `../cli/experiments/factory/v1alpha1/providers/kubernetes/transformers/cronjob_transformer.cue` → `v1alpha1/providers/kubernetes/transformers/`
- [x] 5.9 Copy `../cli/experiments/factory/v1alpha1/providers/kubernetes/transformers/service_transformer.cue` → `v1alpha1/providers/kubernetes/transformers/`
- [x] 5.10 Copy `../cli/experiments/factory/v1alpha1/providers/kubernetes/transformers/configmap_transformer.cue` → `v1alpha1/providers/kubernetes/transformers/`
- [x] 5.11 Copy `../cli/experiments/factory/v1alpha1/providers/kubernetes/transformers/secret_transformer.cue` → `v1alpha1/providers/kubernetes/transformers/`
- [x] 5.12 Copy `../cli/experiments/factory/v1alpha1/providers/kubernetes/transformers/pvc_transformer.cue` → `v1alpha1/providers/kubernetes/transformers/`
- [x] 5.13 Copy `../cli/experiments/factory/v1alpha1/providers/kubernetes/transformers/crd_transformer.cue` → `v1alpha1/providers/kubernetes/transformers/`
- [x] 5.14 Copy `../cli/experiments/factory/v1alpha1/providers/kubernetes/transformers/role_transformer.cue` → `v1alpha1/providers/kubernetes/transformers/`
- [x] 5.15 Copy `../cli/experiments/factory/v1alpha1/providers/kubernetes/transformers/sa_trait_transformer.cue` → `v1alpha1/providers/kubernetes/transformers/`
- [x] 5.16 Copy `../cli/experiments/factory/v1alpha1/providers/kubernetes/transformers/sa_resource_transformer.cue` → `v1alpha1/providers/kubernetes/transformers/`
- [x] 5.17 Copy `../cli/experiments/factory/v1alpha1/providers/kubernetes/transformers/ingress_transformer.cue` → `v1alpha1/providers/kubernetes/transformers/`
- [x] 5.18 Copy `../cli/experiments/factory/v1alpha1/providers/kubernetes/transformers/hpa_transformer.cue` → `v1alpha1/providers/kubernetes/transformers/`

## 6. Bug Fixes (HPA & Ingress Release-Prefix)

- [x] 6.1 Fix `v1alpha1/providers/kubernetes/transformers/hpa_transformer.cue`: add release-prefix to `metadata.name` (`"\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"`)
- [x] 6.2 Fix `v1alpha1/providers/kubernetes/transformers/hpa_transformer.cue`: update `scaleTargetRef.name` to use release-prefixed name
- [x] 6.3 Fix `v1alpha1/providers/kubernetes/transformers/ingress_transformer.cue`: add release-prefix to `metadata.name`
- [x] 6.4 Fix `v1alpha1/providers/kubernetes/transformers/ingress_transformer.cue`: update backend `service.name` references to use release-prefixed name

## 7. Examples

- [x] 7.1 Keep existing catalog examples (`v1alpha1/examples/components/`, `v1alpha1/examples/modules/`, `v1alpha1/examples/out.cue`) in place
- [x] 7.2 Copy `../cli/experiments/factory/v1alpha1/examples/bundles/gamestack/` → `v1alpha1/examples/bundles/gamestack/`
- [x] 7.3 Copy `../cli/experiments/factory/v1alpha1/examples/modules/minecraft/` → `v1alpha1/examples/modules/minecraft/`
- [x] 7.4 Copy `../cli/experiments/factory/v1alpha1/examples/modules/mc-monitor/` → `v1alpha1/examples/modules/mc-monitor/`
- [x] 7.5 Copy `../cli/experiments/factory/v1alpha1/examples/modules/mc-router/` → `v1alpha1/examples/modules/mc-router/`
- [x] 7.6 Copy `../cli/experiments/factory/v1alpha1/examples/modules/velocity/` → `v1alpha1/examples/modules/velocity/`
- [x] 7.7 Copy `../cli/experiments/factory/v1alpha1/examples/releases/` → `v1alpha1/examples/releases/`

## 8. Metadata & Cleanup

- [x] 8.1 Replace `v1alpha1/INDEX.md` with the experiments version (from `../cli/experiments/factory/v1alpha1/INDEX.md`)
- [x] 8.2 Delete `v1alpha1/out.cue` (empty placeholder not present in experiments)
- [x] 8.3 Verify `v1alpha1/cue.mod/module.cue` matches between experiments and catalog; update if needed

## 9. Validation

- [x] 9.1 Run `task fmt` from catalog root — all CUE files formatted
- [x] 9.2 Run `task vet` from catalog root — all definitions evaluate cleanly
- [x] 9.3 Verify no import cycle errors in `v1alpha1/core/helpers/`
