package schemas

/////////////////////////////////////////////////////////////////
//// Security Schemas
/////////////////////////////////////////////////////////////////

#WorkloadIdentitySchema: {
	name!:           string
	automountToken?: bool
}

// #ImagePullSecretsSchema lists pre-existing K8s Secrets used to pull
// container images. Each entry is a LocalObjectReference to a Secret
// of type kubernetes.io/dockerconfigjson in the same namespace as the pod.
//
// OPM does not create these Secrets — they must already exist in the
// cluster (typically managed by an external secret operator or platform team).
#ImagePullSecretsSchema: [...{name!: string}]

// Security context constraints for container and pod-level hardening.
//
// Fields apply at different levels in Kubernetes:
//   Pod-level (spec.securityContext):    runAsNonRoot, runAsUser, runAsGroup, fsGroup,
//                                        supplementalGroups
//   Container-level (containers[].securityContext): privileged, allowPrivilegeEscalation,
//                                        capabilities, readOnlyRootFilesystem,
//                                        runAsNonRoot, runAsUser, runAsGroup
//
// When privileged: true is set, it grants the container full host access and
// supersedes most other security constraints. Only set on workloads that
// explicitly require host-level access (e.g. Docker-in-Docker, GPU streaming).
#SecurityContextSchema: {
	// Grant full host access (equivalent to running as root on the host).
	// Required for Docker-in-Docker and workloads that need device-level access.
	// Supersedes allowPrivilegeEscalation, capabilities, and most other constraints.
	privileged?: bool

	// Run container as non-root user
	runAsNonRoot?: bool
	// Specific user ID to run as
	runAsUser?: int
	// Specific group ID to run as
	runAsGroup?: int
	// Group ID applied to mounted volumes; kubelet chowns volume contents to this GID on mount
	fsGroup?: int
	// Additional GIDs applied to the pod's processes (pod-level only).
	// Used to grant access to shared devices or files owned by supplemental groups.
	// Example: [44, 109] grants video and render group access for /dev/dri on Linux.
	supplementalGroups?: [...int]
	// Mount the root filesystem as read-only
	readOnlyRootFilesystem?: bool
	// Prevent privilege escalation via setuid/setgid binaries
	allowPrivilegeEscalation?: bool
	// Linux capabilities
	capabilities?: {
		add?: [...string]
		drop?: [...string] | ["ALL"]
	}
}

// Standalone service account identity
#ServiceAccountSchema: {
	name!:           string
	automountToken?: bool
}

// Single RBAC permission rule
#PolicyRuleSchema: {
	apiGroups!: [...string]
	resources!: [...string]
	verbs!: [...string]
	// Restrict the rule to named instances of the listed resources. Omit to allow all.
	// Note Kubernetes does not honour resourceNames for list/watch/create.
	resourceNames?: [...string]
}

// Role subject — embeds an identity directly via CUE reference
#RoleSubjectSchema: {#WorkloadIdentitySchema | #ServiceAccountSchema}

// RBAC role with rules and CUE-referenced subjects
#RoleSchema: {
	name!: string
	scope: *"namespace" | "cluster"
	rules!: [...#PolicyRuleSchema] & [_, ...]
	subjects!: [...#RoleSubjectSchema] & [_, ...]
}

#EncryptionConfigSchema: {
	atRest:    bool
	inTransit: bool
}

//////////////////////////////////////////////////////////////////
//// cert-manager Schemas
//////////////////////////////////////////////////////////////////

// IssuerRef embedded in Certificate — identifies which Issuer signs the cert
#CertificateIssuerRefSchema: {
	name!:  string
	kind!:  "Issuer" | "ClusterIssuer"
	group?: string
}

// PrivateKey configuration
#CertificatePrivateKeySchema: {
	algorithm?:      *"RSA" | "ECDSA" | "Ed25519"
	size?:           int
	rotationPolicy?: "Never" | "Always"
}

// Keystore output — cert-manager can additionally write the cert as JKS/PKCS#12
// into the target Secret. The password may come from a Secret or, since
// cert-manager v1.17, be given inline as a literal (the two are mutually exclusive).
#CertificateKeystoreBaseSchema: {
	create!:            bool
	password?:          string
	passwordSecretRef?: #SecretKeyRefSchema
}

// JKS keystore output — Java KeyStore variant of #CertificateKeystoreBaseSchema
#CertificateJKSKeystoreSchema: #CertificateKeystoreBaseSchema & {
	// Alias the certificate is stored under inside the keystore.
	alias?: string
}

// PKCS#12 keystore output — PKCS#12 variant of #CertificateKeystoreBaseSchema
#CertificatePKCS12KeystoreSchema: #CertificateKeystoreBaseSchema & {
	// Encryption/algorithm profile, e.g. LegacyRC2, LegacyDES, Modern2023.
	profile?: string
}

// Certificate spec — defines the desired TLS certificate
#CertificateSchema: {
	secretName!: string
	issuerRef!:  #CertificateIssuerRefSchema
	dnsNames?: [...string]
	ipAddresses?: [...string]
	uris?: [...string]
	emailAddresses?: [...string]
	commonName?:  string
	duration?:    string
	renewBefore?: string
	// Renew when this percentage of the certificate's lifetime remains (cert-manager v1.16+).
	// Mutually exclusive with renewBefore.
	renewBeforePercentage?: int & >=1 & <=99
	privateKey?:            #CertificatePrivateKeySchema
	usages?: [...("digital signature" | "key encipherment" | "server auth" | "client auth" | "cert sign" | "crl sign")]
	// Number of CertificateRequest revisions kept. Upstream defaults this to 1 as of
	// cert-manager v1.18 (previously unbounded).
	revisionHistoryLimit?: int & >=1
	// Extra labels/annotations copied onto the generated TLS Secret.
	secretTemplate?: {
		labels?: {[string]: string}
		annotations?: {[string]: string}
	}
	keystores?: {
		jks?:    #CertificateJKSKeystoreSchema
		pkcs12?: #CertificatePKCS12KeystoreSchema
	}
	// Mark the certificate as a CA (allows it to sign other certificates).
	isCA?: bool
	// x509 name constraints for CA certificates (cert-manager v1.15+).
	nameConstraints?: {
		critical?:  bool
		permitted?: #CertificateNameConstraintItemSchema
		excluded?:  #CertificateNameConstraintItemSchema
	}
}

// One side (permitted or excluded) of an x509 name constraints extension
#CertificateNameConstraintItemSchema: {
	dnsDomains?: [...string]
	ipRanges?: [...string]
	emailAddresses?: [...string]
	uriDomains?: [...string]
}

// ACME HTTP-01 solver — uses HTTP challenge to prove domain ownership
#AcmeHttp01SolverSchema: {
	// Use existing Ingress class for the challenge
	ingress?: {
		class?:            string
		ingressClassName?: string
	}
	// Use Gateway API HTTPRoute for the challenge (cert-manager v1.15+)
	gatewayHTTPRoute?: {
		parentRefs?: [...{
			name!:        string
			namespace?:   string
			kind?:        string
			group?:       string
			sectionName?: string
		}]
		serviceType?: "NodePort" | "ClusterIP"
		labels?: {[string]: string}
	}
}

// Reference to a key within a Secret — used by every DNS-01 provider for credentials.
#SecretKeyRefSchema: {
	name!: string
	key!:  string
}

// ACME DNS-01 solver — proves domain ownership by writing a TXT record.
// Required for wildcard certificates and for clusters with no inbound HTTP reachability.
// Only the most common providers are modelled explicitly; use `webhook` for the rest.
#AcmeDns01SolverSchema: {
	// How CNAME records are followed when locating the zone to write the TXT record into.
	// "Follow" is required when delegating _acme-challenge to another zone.
	cnameStrategy?: "None" | "Follow"

	cloudflare?: {
		email?:             string
		apiTokenSecretRef?: #SecretKeyRefSchema
		apiKeySecretRef?:   #SecretKeyRefSchema
	}
	route53?: {
		// region is optional as of cert-manager v1.21 (inferred from the environment when unset).
		region?:                   string
		hostedZoneID?:             string
		accessKeyID?:              string
		accessKeyIDSecretRef?:     #SecretKeyRefSchema
		secretAccessKeySecretRef?: #SecretKeyRefSchema
		role?:                     string
	}
	azureDNS?: {
		subscriptionID!:        string
		resourceGroupName!:     string
		hostedZoneName?:        string
		environment?:           string
		clientID?:              string
		tenantID?:              string
		clientSecretSecretRef?: #SecretKeyRefSchema
		managedIdentity?: {
			clientID?:   string
			resourceID?: string
		}
	}
	cloudDNS?: {
		project!:                 string
		hostedZoneName?:          string
		serviceAccountSecretRef?: #SecretKeyRefSchema
	}
	digitalocean?: {
		tokenSecretRef!: #SecretKeyRefSchema
	}
	// RFC2136 dynamic DNS update (e.g. BIND, PowerDNS).
	rfc2136?: {
		nameserver!:          string
		tsigKeyName?:         string
		tsigAlgorithm?:       string
		tsigSecretSecretRef?: #SecretKeyRefSchema
	}
	// Escape hatch for any provider served by a cert-manager DNS-01 webhook solver.
	webhook?: {
		groupName!:  string
		solverName!: string
		config?: {...}
	}
}

// ACME solver — selects which challenge type to use
#AcmeSolverSchema: {
	selector?: {
		dnsNames?: [...string]
		dnsZones?: [...string]
		matchLabels?: {[string]: string}
	}
	http01?: #AcmeHttp01SolverSchema
	dns01?:  #AcmeDns01SolverSchema
}

// IssuerSpec — common configuration for Issuer and ClusterIssuer
#IssuerSpecSchema: {
	// ACME (Let's Encrypt, ZeroSSL, etc.)
	acme?: {
		server!: string
		email!:  string
		privateKeySecretRef!: {
			name!: string
		}
		skipTLSVerify?: bool
		// Request a named certificate profile from the ACME server (cert-manager v1.18+).
		// Supported values are published by the CA's ACME directory.
		profile?: string
		// Pin the issuing chain by its root CA common name (e.g. "ISRG Root X1").
		preferredChain?: string
		// PEM CA bundle used to verify the ACME server — for private ACME CAs such as step-ca.
		caBundle?: string
		// External Account Binding, required by some CAs (e.g. ZeroSSL, Sectigo).
		externalAccountBinding?: {
			keyID!:        string
			keySecretRef!: #SecretKeyRefSchema
			keyAlgorithm?: "HS256" | "HS384" | "HS512"
		}
		solvers?: [...#AcmeSolverSchema]
	}
	// CA issuer — signs certs using a CA certificate stored in a Secret
	ca?: {
		secretName!: string
	}
	// Self-signed issuer — signs with its own key (useful for bootstrapping)
	selfSigned?: {}
	// HashiCorp Vault issuer
	vault?: {
		server!: string
		path!:   string
		auth!: {
			tokenSecretRef?: {
				name!: string
				key!:  string
			}
			...
		}
	}
}

// Issuer schema (namespace-scoped)
#IssuerSchema: #IssuerSpecSchema

// ClusterIssuer schema (cluster-scoped — same spec shape as Issuer)
#ClusterIssuerSchema: #IssuerSpecSchema
