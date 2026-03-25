# v1alpha1 — Definition Index

CUE module: `opmodel.dev/cert_manager/v1alpha1@v1`

---

## Project Structure

```
+-- providers/
|   +-- kubernetes/
|       +-- transformers/
+-- resources/
    +-- security/
```

---

## Providers

### kubernetes

| Definition | File | Description |
|---|---|---|
| `#Provider` | `providers/kubernetes/provider.cue` | CertManagerKubernetesProvider transforms cert-manager components to Kubernetes native resources |

### kubernetes/transformers

| Definition | File | Description |
|---|---|---|
| `#CertificateTransformer` | `providers/kubernetes/transformers/certificate_transformer.cue` | #CertificateTransformer converts CertificateResource to a cert-manager Certificate (cert-manager |
| `#ClusterIssuerTransformer` | `providers/kubernetes/transformers/cluster_issuer_transformer.cue` | #ClusterIssuerTransformer converts ClusterIssuerResource to a cert-manager ClusterIssuer (cert-manager |
| `#IssuerTransformer` | `providers/kubernetes/transformers/issuer_transformer.cue` | #IssuerTransformer converts IssuerResource to a cert-manager Issuer (cert-manager |
| `#TestCtx` | `providers/kubernetes/transformers/test_helpers.cue` | #TestCtx constructs a minimal concrete #TransformerContext for transformer tests |

---

## Resources

### security

| Definition | File | Description |
|---|---|---|
| `#Certificate` | `resources/security/certificate.cue` |  |
| `#CertificateDefaults` | `resources/security/certificate.cue` |  |
| `#CertificateResource` | `resources/security/certificate.cue` |  |
| `#ClusterIssuer` | `resources/security/cluster_issuer.cue` |  |
| `#ClusterIssuerDefaults` | `resources/security/cluster_issuer.cue` |  |
| `#ClusterIssuerResource` | `resources/security/cluster_issuer.cue` |  |
| `#Issuer` | `resources/security/issuer.cue` |  |
| `#IssuerDefaults` | `resources/security/issuer.cue` |  |
| `#IssuerResource` | `resources/security/issuer.cue` |  |

---

