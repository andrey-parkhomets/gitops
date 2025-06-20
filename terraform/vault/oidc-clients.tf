module "argo" {
  source = "./modules/oidc-client"

  depends_on = [
    vault_identity_oidc_provider.kubefirst
  ]

  app_name               = "argo"
  oidc_provider_key_name = vault_identity_oidc_key.key.name
  redirect_uris = [
    "https://argo.kubefirst.dev/oauth2/callback",
  ]
  secret_mount_path = vault_mount.secret.path
}

module "argocd" {
  source = "./modules/oidc-client"

  depends_on = [
    vault_identity_oidc_provider.kubefirst
  ]

  app_name               = "argocd"
  oidc_provider_key_name = vault_identity_oidc_key.key.name
  redirect_uris = [
    "https://argocd.kubefirst.dev/auth/callback",
  ]
  secret_mount_path = vault_mount.secret.path
}

module "gitlab" {
  source = "./modules/oidc-client"

  depends_on = [
    vault_identity_oidc_provider.kubefirst
  ]

  app_name               = "gitlab"
  oidc_provider_key_name = vault_identity_oidc_key.key.name
  redirect_uris = [
    "https://gitlab.kubefirst.dev/users/auth/openid_connect/callback",
  ]
  secret_mount_path = vault_mount.secret.path
}

module "console" {
  source = "./modules/oidc-client"

  depends_on = [
    vault_identity_oidc_provider.kubefirst
  ]

  app_name               = "console"
  oidc_provider_key_name = vault_identity_oidc_key.key.name
  redirect_uris = [
    "https://kubefirst.kubefirst.dev/api/auth/callback/vault",
  ]
  secret_mount_path = vault_mount.secret.path
}
