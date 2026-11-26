# Infrastructure

The identity stack for every project's admin section, managed here with
[OpenTofu](https://opentofu.org), the open-source fork of Terraform (same HCL,
providers and state format): the Zero Trust organisation, its login method,
one admin Access application per project with one shared owner policy,
service tokens for machine-to-machine reads, and Turnstile widgets. The only things outside OpenTofu are the state bucket (it
must exist before OpenTofu can use it) and the CI credentials below.

State lives in the R2 bucket `coraxia-tfstate`, never in git.

## Workflows

| Workflow | Trigger | What it does |
|---|---|---|
| `infra.yml` | PR touching `infra/` (plan); push to `main` (apply); manual | Format check, validate, plan; refuses any plan that deletes or replaces unless run by hand with `allow_deletes` ([Deleting resources](#deleting-resources)). Skips the repository's first push, before credentials exist |
| `bootstrap-state.yml` | Manual | Creates the state bucket if it's missing; safe to re-run |
| `rotate-turnstile-secret.yml` | Manual, on `main` | Rotates one widget's secret ([Rotating a widget's secret](#rotating-a-widgets-secret)) |

## Changing infrastructure

Everything `infra/` declares (the organisation settings, the login method, the
owner policy, every application and every widget) changes only through a PR to
`infra/`, applied by `infra.yml`. The organisation is set read-only in the
dashboard, so a change there is refused; make it in code.

- Before writing to Cloudflare through an API, an MCP tool or the dashboard,
  check whether `infra/` declares that resource. If it does, make the change
  there instead.
- In an emergency, a change by hand needs the maintainer's explicit OK first.
  Then declare the same resource in `infra/` straight away, with an `import`
  block for anything created by hand, so the next apply adopts it instead of
  failing to create it again.

## Deleting resources

`infra.yml` refuses a plan that deletes or replaces anything, so a merge that
removes a resource fails its apply and changes nothing. To apply it on
purpose, read the failed run's plan, then run "Infra" by hand on `main` with
`allow_deletes` ticked. It runs in the `infra` environment, so only `main` can
do it. Resources with `prevent_destroy` still refuse: removing that is the
teardown below.

## What it manages

- **The Zero Trust organisation**, adopted with an `import` block.
  `is_ui_read_only` and `ui_read_only_toggle_reason` are set, so the dashboard
  is read-only and says why. `service_token_inactivity` is declared in full
  with enforcement off, because the API rejects an update that carries only
  part of it. Every other organisation setting is left as it is
  (`ignore_changes`).
- **The login method**: the Cloudflare login method (sign in with a
  Cloudflare account), adopted with an `import` block, restricted to members of
  the account.
- **One owner policy**: allows the one email in `OWNER_EMAIL`.
- **One admin application per project**, from the `apps` map. Every
  application gets the same settings, and none can be changed per project: the
  login method is the only one allowed and is signed in to without a choice
  screen, the binding cookie and `HttpOnly` are on, `SameSite` is `lax`,
  sessions last 8 hours, and the owner policy comes first. An application
  that a service token lists also gets a service-auth policy for those tokens.
- **Service tokens**, from the `service_tokens` map, each listing the
  applications it may reach. They never expire, so a daily job never stops
  without warning; rotate one by raising its `client_secret_version`.
- **Turnstile widgets**, from the `widgets` map, with `prevent_destroy`.

## Setup

1. The Cloudflare account has a Zero Trust organisation and its Cloudflare
   login method.
2. Create the CI tokens below, the R2 state credentials, and the GitHub
   secrets and variables: `node <plugin>/skills/bootstrap/scripts/secrets.mjs cloudflare-tokens <project dir>`
   does the CI tokens, or follow this page by hand.
3. Run "Bootstrap OpenTofu state bucket".
4. Run "Infra" (dispatch it, or merge a change under `infra/`).

### Cloudflare API tokens

This section is kept in the private vault.

### R2 state credentials

This section is kept in the private vault.

### OpenTofu version

`infra.yml` pins OpenTofu exactly in `tofu_version`. Dependabot doesn't bump
it. To upgrade, take the newest `opentofu/opentofu` release that is more than
72 hours old (not a pre-release), change `tofu_version`, and run the same
version locally.

### Variables

`CLOUDFLARE_ACCOUNT_ID` as a repository variable. It isn't confidential.

`ACCESS_LOGIN_METHOD_ID` as a repository variable: the ID of the account's
Cloudflare login method (Zero Trust → Integrations → Identity providers). It
isn't confidential. The first apply adopts that login method.

`OWNER_EMAIL` as a repository secret: the one email every admin application
lets in. It is never committed.

## Adding a project's admin section

1. Add an entry to `apps` in `infra/terraform.tfvars.json`, keyed by project:

   ```json
   {
     "apps": {
       "example": { "name": "Example admin", "domain": "admin.example.com" }
     },
     "widgets": {}
   }
   ```

2. Open a PR. The plan shows the new application; merge it and the apply
   creates it.
3. Read the outputs: `app_aud["example"]` and `team_domain`. In the project's
   `wrangler.jsonc`, set `ACCESS_AUD` and `ACCESS_TEAM_DOMAIN` to them. The
   Worker checks the Access token against both.

## Adding a service token

This section is kept in the private vault.

## Adding a widget

Add an entry to `widgets` in `infra/terraform.tfvars.json`, keyed by project,
with its `name` and `domains` (and `mode`, `managed` by default):

```json
{
  "apps": {},
  "widgets": {
    "example": { "name": "example-forms", "domains": ["example.com"] }
  }
}
```

After the apply, `widget_sitekey["example"]` is the sitekey for the page. The
widget's secret isn't an output: read it on the widget's Turnstile page in the
Cloudflare dashboard.

## Rotating a widget's secret

This section is kept in the private vault.

## Importing existing applications, policies and widgets

An application, policy or widget that already exists is adopted with an
`import` block, not recreated. A runbook for importing existing projects'
resources will be linked here.

## Account guidance

This section is kept in the private vault.

## Disaster recovery

1. Run "Bootstrap OpenTofu state bucket".
2. Run "Infra" to recreate everything managed here.

## Teardown

Deliberately deleting the stack:

1. Set `is_ui_read_only` to `false` in a PR and let Infra apply it, so the
   dashboard can be edited again.
2. Remove the organisation and the login method from state, so the destroy
   leaves the account's own Zero Trust organisation and login method alone:
   `tofu state rm cloudflare_zero_trust_organization.this cloudflare_zero_trust_access_identity_provider.login`.
3. Remove `prevent_destroy` from every resource in a PR (the infra workflow
   refuses plans that delete, so run the destroy locally).
4. Locally, with the infra apply token and state credentials in your
   environment:
   `tofu init -backend-config="endpoints={s3=\"https://<account id>.r2.cloudflarestorage.com\"}"`
   then `tofu destroy`.
5. Empty and delete the `coraxia-tfstate` bucket in the dashboard.
6. Revoke the two Cloudflare tokens and the R2 credentials.
