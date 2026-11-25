output "team_domain" {
  description = "The Zero Trust organisation's team domain, for each project's ACCESS_TEAM_DOMAIN."
  value       = cloudflare_zero_trust_organization.this.auth_domain
}

output "app_aud" {
  description = "Each admin application's audience tag, by project, for the project's ACCESS_AUD."
  value       = { for key, app in cloudflare_zero_trust_access_application.admin : key => app.aud }
}

output "widget_sitekey" {
  description = "Each Turnstile widget's sitekey, by project."
  value       = { for key, widget in cloudflare_turnstile_widget.site : key => widget.sitekey }
}

output "service_tokens" {
  description = "Each service token's client id and secret, by name. Sensitive, so it never prints in the public apply log: read it with tofu output -json service_tokens."
  sensitive   = true
  value = {
    for key, token in cloudflare_zero_trust_access_service_token.this : key => {
      client_id     = token.client_id
      client_secret = token.client_secret
    }
  }
}
