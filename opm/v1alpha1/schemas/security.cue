package schemas

/////////////////////////////////////////////////////////////////
//// Security Schemas
/////////////////////////////////////////////////////////////////

#WorkloadIdentitySchema: {
	name!:           string
	automountToken?: bool
}

// Security context constraints for container and pod-level hardening.
//
// Fields apply at different levels in Kubernetes:
//   Pod-level (spec.securityContext):    runAsNonRoot, runAsUser, runAsGroup, fsGroup
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

// Certificate spec — defines the desired TLS certificate
#CertificateSchema: {
	secretName!: string
	issuerRef!:  #CertificateIssuerRefSchema
	dnsNames?: [...string]
	ipAddresses?: [...string]
	commonName?:  string
	duration?:    string
	renewBefore?: string
	privateKey?:  #CertificatePrivateKeySchema
	usages?: [...("digital signature" | "key encipherment" | "server auth" | "client auth" | "cert sign" | "crl sign")]
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

// ACME solver — selects which challenge type to use
#AcmeSolverSchema: {
	selector?: {
		dnsNames?: [...string]
		dnsZones?: [...string]
	}
	http01?: #AcmeHttp01SolverSchema
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
