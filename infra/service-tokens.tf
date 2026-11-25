locals {
  app_service_tokens = {
    for app in keys(var.apps) : app => [for key, token in var.service_tokens : key if contains(token.apps, app)]
  }
  service_token_apps = { for app, tokens in local.app_service_tokens : app => tokens if length(tokens) > 0 }
}

resource "cloudflare_zero_trust_access_service_token" "this" {
  for_each = var.service_tokens

  account_id = var.cloudflare_account_id
  name       = each.value.name
  duration   = "forever"
}

resource "cloudflare_zero_trust_access_policy" "service" {
  for_each = local.service_token_apps

  account_id = var.cloudflare_account_id
  name       = "Allow ${var.apps[each.key].name}'s service tokens"
  decision   = "non_identity"

  include = [for token in each.value : {
    service_token = {
      token_id = cloudflare_zero_trust_access_service_token.this[token].id
    }
  }]
}
