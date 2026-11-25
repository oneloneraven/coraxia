resource "cloudflare_zero_trust_access_application" "admin" {
  for_each = var.apps

  account_id                 = var.cloudflare_account_id
  name                       = each.value.name
  domain                     = each.value.domain
  type                       = "self_hosted"
  session_duration           = "8h"
  allowed_idps               = [cloudflare_zero_trust_access_identity_provider.login.id]
  auto_redirect_to_identity  = true
  enable_binding_cookie      = true
  http_only_cookie_attribute = true
  same_site_cookie_attribute = "lax"

  policies = concat(
    [{
      id         = cloudflare_zero_trust_access_policy.owner.id
      precedence = 1
    }],
    contains(keys(local.service_token_apps), each.key) ? [{
      id         = cloudflare_zero_trust_access_policy.service[each.key].id
      precedence = 2
    }] : [],
  )
}
