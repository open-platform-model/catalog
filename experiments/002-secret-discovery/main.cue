package main

import "strings"

//////////////////////////////////////////////////////////
//// Global Schemas
//////////////////////////////////////////////////////////

#NameType: string & =~"^[a-z0-9]([a-z0-9-]*[a-z0-9])?$" & strings.MinRunes(1) & strings.MaxRunes(63)

// #Secret is the CONTRACT type that module authors place on
// sensitive fields. It is a disjunction of fulfillment variants.
// Users provide values that resolve to one of these variants.
//
// The $opm discriminator enables auto-discovery via CUE comprehensions.
// The $secretName and $dataKey fields carry routing information:
//   $secretName → K8s Secret resource name (grouping key)
//   $dataKey    → data key within that K8s Secret
//
// These are set by the author in the schema declaration.
// Users never need to set them — CUE unification propagates them.
#Secret: #SecretLiteral | #SecretRef

// #SecretLiteral: user provides the actual value.
// The transformer creates a K8s Secret with this data entry.
#SecretLiteral: {
	$opm:         "secret"
	$secretName!: #NameType
	$dataKey!:    string
	description?: string
	value!:       string
}

// #SecretRef: user references an existing secret source.
// For source "k8s": references a pre-existing K8s Secret (no resource created).
// For source "esc": the transformer creates an ExternalSecret CR.
#SecretRef: {
	$opm:         "secret"
	$secretName!: #NameType
	$dataKey!:    string
	description?: string
	source!:      *"k8s" | "esc"
	path!:        string    // K8s Secret name (for k8s) or external path (for esc)
	remoteKey!:   string    // key within the referenced secret
}

//////////////////////////////////////////////////////////
//// Secret Discovery
//////////////////////////////////////////////////////////

// _#discoverSecrets walks a resolved #config (up to 3 levels deep)
// and collects all fields whose value is a #Secret.
//
// The detection uses a negation test:
//   (v & {$opm: !="secret", ...}) == _|_
// This produces bottom ONLY when $opm is already "secret" on the value.
// Anonymous open structs without $opm get the constraint added
// harmlessly (no conflict), so they are correctly skipped.
// Scalars (string, int, bool) fail the struct check and are skipped.
//
// The result is a flat map of all discovered secrets, keyed by
// their path (e.g., "dbUser", "database/password", "auth/tokens/api").
// The path keys are internal identifiers — grouping uses $secretName/$dataKey.
_#discoverSecrets: {
	#in: {...}
	out: {
		// Level 1: direct fields
		for k1, v1 in #in
		if ((v1 & {$opm: !="secret", ...}) == _|_)
		if ((v1 & {...}) != _|_) {
			(k1): v1
		}

		// Level 2: one level of nesting
		for k1, v1 in #in
		if ((v1 & {$opm: !="secret", ...}) != _|_)
		if ((v1 & {...}) != _|_) {
			for k2, v2 in v1
			if ((v2 & {$opm: !="secret", ...}) == _|_)
			if ((v2 & {...}) != _|_) {
				("\(k1)/\(k2)"): v2
			}
		}

		// Level 3: two levels of nesting
		for k1, v1 in #in
		if ((v1 & {$opm: !="secret", ...}) != _|_)
		if ((v1 & {...}) != _|_) {
			for k2, v2 in v1
			if ((v2 & {$opm: !="secret", ...}) != _|_)
			if ((v2 & {...}) != _|_) {
				for k3, v3 in v2
				if ((v3 & {$opm: !="secret", ...}) == _|_)
				if ((v3 & {...}) != _|_) {
					("\(k1)/\(k2)/\(k3)"): v3
				}
			}
		}
	}
}

// _#groupSecrets takes a flat map of discovered secrets and groups
// them by $secretName, keyed by $dataKey.
// The result structure mirrors the K8s Secret resource layout:
//   { "db-creds": { username: #Secret, password: #Secret }, ... }
_#groupSecrets: {
	#in: {...}
	out: {
		for _k, v in #in {
			(v.$secretName): (v.$dataKey): v
		}
	}
}

//////////////////////////////////////////////////////////
//// Example Module: Web App with Database
//////////////////////////////////////////////////////////

// Schema — defined by the module author.
// #Secret fields declare WHAT is sensitive and WHERE it should land.
// The user decides HOW to provide the value (literal or ref).

#config: {
	// Flat secrets (level 1)
	dbUser: #Secret & {
		$secretName: "db-credentials"
		$dataKey:    "username"
		description: "Database username"
	}
	dbPassword: #Secret & {
		$secretName: "db-credentials"
		$dataKey:    "password"
		description: "Database password"
	}

	// Another secret group
	apiKey: #Secret & {
		$secretName: "api-credentials"
		$dataKey:    "api-key"
	}

	// Non-secret scalar fields
	logLevel: string | *"info"
	replicas: int | *1

	// Non-secret nested struct (anonymous, open — tests false positive rejection)
	database: {
		host: string | *"localhost"
		port: int | *5432
	}

	// Nested secrets (level 2)
	cache: {
		password: #Secret & {
			$secretName: "cache-credentials"
			$dataKey:    "password"
			description: "Redis cache password"
		}
		host: string | *"redis://localhost"
	}

	// Deeply nested secrets (level 3)
	integrations: {
		payments: {
			stripeKey: #Secret & {
				$secretName: "stripe-credentials"
				$dataKey:    "secret-key"
				description: "Stripe API secret key"
			}
			webhookSecret: #Secret & {
				$secretName: "stripe-credentials"
				$dataKey:    "webhook-secret"
				description: "Stripe webhook signing secret"
			}
		}
		email: {
			provider: string | *"sendgrid"
			apiKey: #Secret & {
				$secretName: "email-credentials"
				$dataKey:    "api-key"
			}
		}
	}
}

//////////////////////////////////////////////////////////
//// User Values
//////////////////////////////////////////////////////////

// Concrete values — set by the end-user.
// The user provides fulfillment for each #Secret field.
// Some are literals, some reference existing K8s Secrets.

values: #config & {
	// Literal — creates a K8s Secret entry
	dbUser: {value: "admin"}

	// K8s Ref — references pre-existing Secret "myapp-db-secrets"
	dbPassword: {
		source:    "k8s"
		path:      "myapp-db-secrets"
		remoteKey: "db-password"
	}

	// Literal
	apiKey: {value: "sk_live_abc123"}

	// Non-secret overrides
	logLevel: "debug"
	replicas: 3
	database: {host: "db.prod.internal", port: 5432}

	// Nested: ESC ref — creates an ExternalSecret CR
	cache: {
		password: {
			source:    "esc"
			path:      "production/redis"
			remoteKey: "password"
		}
		host: "redis://cache.prod.internal"
	}

	// Deeply nested: mix of literals
	integrations: {
		payments: {
			stripeKey:     {value: "sk_live_stripe_key"}
			webhookSecret: {value: "whsec_stripe_webhook"}
		}
		email: {
			apiKey: {value: "SG.sendgrid_key"}
		}
	}
}

//////////////////////////////////////////////////////////
//// Auto-Discovery & Grouping
//////////////////////////////////////////////////////////

// Step 1: Discover all #Secret fields from resolved values
_discovered: (_#discoverSecrets & {#in: values}).out

// Step 2: Group by $secretName / $dataKey → K8s Secret resource layout
spec: secrets: (_#groupSecrets & {#in: _discovered}).out

//////////////////////////////////////////////////////////
//// Env Var Wiring
//////////////////////////////////////////////////////////

// The author wires env vars to #config values.
// `from:` carries the resolved #Secret (with routing info).
// `value:` carries non-secret string values.
// The transformer reads `from:` and dispatches:
//   #SecretLiteral → secretKeyRef: { name: $secretName, key: $dataKey }
//   #SecretRef(k8s) → secretKeyRef: { name: path, key: remoteKey }
//   #SecretRef(esc) → secretKeyRef: { name: $secretName, key: $dataKey }
//                     (ESC creates the target Secret named $secretName)

spec: container: env: {
	DB_USER:        {from: values.dbUser}
	DB_PASSWORD:    {from: values.dbPassword}
	API_KEY:        {from: values.apiKey}
	LOG_LEVEL:      {envValue: values.logLevel}
	CACHE_PASSWORD: {from: values.cache.password}
	STRIPE_KEY:     {from: values.integrations.payments.stripeKey}
	STRIPE_WEBHOOK: {from: values.integrations.payments.webhookSecret}
	EMAIL_API_KEY:  {from: values.integrations.email.apiKey}
}

//////////////////////////////////////////////////////////
//// Simulated Transformer Output
//////////////////////////////////////////////////////////

// This section simulates what the SecretTransformer would produce
// from spec.secrets. In the real system, this is Go code.

_transformerOutput: {
	for _secretName, _entries in spec.secrets {
		// Collect literals for this group
		let _literals = {
			for _dk, _entry in _entries
			if (((_entry & #SecretLiteral) & {$opm: !="secret", ...}) == _|_)
			if (_entry.value != _|_) {
				(_dk): _entry.value
			}
		}

		// Emit K8s Secret if there are any literal entries
		if len(_literals) > 0 {
			"Secret/\(_secretName)": {
				apiVersion: "v1"
				kind:       "Secret"
				metadata: name: _secretName
				data: _literals
			}
		}

		// Collect ESC refs for this group
		for _dk, _entry in _entries
		if (_entry & #SecretRef) != _|_
		if _entry.source == "esc" {
			"ExternalSecret/\(_secretName)": {
				apiVersion: "external-secrets.io/v1beta1"
				kind:       "ExternalSecret"
				metadata: name: _secretName
				spec: {
					target: name: _secretName
					data: [{
						secretKey: _dk
						remoteRef: {
							key:      _entry.path
							property: _entry.remoteKey
						}
					}]
				}
			}
		}

		// K8s refs: no resource emitted (pre-existing)
	}
}

// Simulated env var resolution
_envTransformerOutput: {
	for _envName, _envVar in spec.container.env {
		if _envVar.from != _|_ {
			let _s = _envVar.from
			if (_s.value != _|_) {
				// #SecretLiteral → use $secretName/$dataKey
				(_envName): {
					name: _envName
					valueFrom: secretKeyRef: {
						name: _s.$secretName
						key:  _s.$dataKey
					}
				}
			}
			if (_s.source != _|_) {
				if _s.source == "k8s" {
					// #SecretRef(k8s) → use path/remoteKey
					(_envName): {
						name: _envName
						valueFrom: secretKeyRef: {
							name: _s.path
							key:  _s.remoteKey
						}
					}
				}
				if _s.source == "esc" {
					// #SecretRef(esc) → ESC creates Secret named $secretName
					(_envName): {
						name: _envName
						valueFrom: secretKeyRef: {
							name: _s.$secretName
							key:  _s.$dataKey
						}
					}
				}
			}
		}
		if _envVar.envValue != _|_ {
			(_envName): {
				name:  _envName
				value: _envVar.envValue
			}
		}
	}
}
