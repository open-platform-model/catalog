package schemas

/////////////////////////////////////////////////////////////////
//// Config Schemas
/////////////////////////////////////////////////////////////////

#SecretSchema: {
	type?: string | *"Opaque" | "kubernetes.io/service-account-token" | "kubernetes.io/dockercfg" | "kubernetes.io/dockerconfigjson" | "kubernetes.io/basic-auth" | "kubernetes.io/ssh-auth" | "kubernetes.io/tls" | "bootstrap.kubernetes.io/token"
	data: [string]: string
}

// ConfigMap specification
#ConfigMapSchema: {
	data: [string]: string
}
