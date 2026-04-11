# Notes — `#Offer` Primitive

Open discussion topics and deferred items.

---

## PlatformCapability CRD (REQUIRES MORE DISCUSSION)

When a Module with `#offers` is installed in a cluster, the OPM Kubernetes controller could dynamically create `PlatformCapability` CRD instances to register the capability in the cluster's API server.

**Envisioned flow:**

1. K8up Module installed (via `opm release apply` or Helm or any method)
2. OPM controller watches for installed modules
3. Controller reads module's `#offers`
4. Controller creates `PlatformCapability` CR for each offer:

```yaml
apiVersion: opmodel.dev/v1alpha1
kind: PlatformCapability
metadata:
  name: backup-v1-k8up
  labels:
    capability.opmodel.dev/claim-fqn: "opmodel.dev/opm/v1alpha1/claims/data/backup@v1"
spec:
  claimFQN: "opmodel.dev/opm/v1alpha1/claims/data/backup@v1"
  offerFQN: "opmodel.dev/k8up/v1alpha1/offers/ops/backup@v1"
  providedBy:
    moduleName: k8up
    moduleVersion: "1.0.0"
  implVersion: "1.2.0"
  status: Active
```

**Open questions:**

- CRD schema — what fields are needed beyond claim FQN, offer FQN, and provider module?
- Lifecycle — what happens when the module is uninstalled? Controller deletes the CR? Finalizers?
- Scope — cluster-scoped or namespace-scoped? Backup capability is typically cluster-wide, but some capabilities might be namespace-scoped.
- Discovery — how does the controller know a module was installed? Watch for ModuleRelease CRDs? Watch for specific labels on Deployments?
- Conflict — what if two modules offer the same capability? Both create PlatformCapability CRs? Priority/ordering?
- Validation webhook — should the controller run an admission webhook that rejects modules with unfulfilled claims?
- Web UI integration — the UI queries PlatformCapability resources to build the capability dashboard

**This topic requires a dedicated design discussion before implementation. The `#Offer` primitive itself is independent of PlatformCapability CRD and can be implemented first.**

---

## Dependency Chains

Modules can have both Claims (on components) and Offers (on module). This creates dependency chains:

- CloudNativePG: offers `#PostgresOffer`, component claims `#S3Claim`
- MinIO: offers `#S3Offer`, component claims nothing
- App module: component claims `#PostgresClaim`

Resolution order: MinIO must be installed before CloudNativePG, which must be installed before the app module.

**Open questions:**

- Cycle detection — is it possible for two modules to create a circular dependency? If Module A claims X and offers Y, and Module B claims Y and offers X, is that valid?
- Whose responsibility — does the controller enforce dependency ordering, or is it the platform team's responsibility to install in the right order?
- Graph representation — should the platform compute a dependency graph from all module claims and offers?

---

## Data Offers Without a Module

External managed services (AWS RDS, ElastiCache, Google Cloud SQL) provide data capabilities (Postgres, Redis) but have no OPM module running in the cluster.

**Current approach:** External binding via `ModuleRelease.values` remains a separate fulfillment path. The platform operator provides connection details directly in the release configuration.

**Open questions:**

- Should there be a lightweight "external service" module that only declares offers without deploying components?
- Should `#Platform` support "virtual offers" for externally managed capabilities?
- How does this affect the capability dashboard — should externally-bound data claims show as "offered" or as a separate category?

---

## Offer Versioning Evolution

The current design uses major-only versions on Offer FQNs (matching the claim FQN pattern) with an optional `implVersion` semver field. If a future need arises for fine-grained version compatibility (e.g., "I need at least v1.2 of the backup claim"), the versioning scheme may need to evolve.

For now, major version match between Claim and Offer is sufficient. Minor/patch evolution happens within the major version contract.
