# Dependency screening register

Every dependency and vendor this project uses, screened against the BDS
movement's
[consumer boycott priority targets](https://bdsmovement.net/Guide-to-BDS-Boycott)
and its
[No Tech for Oppression, Apartheid or Genocide campaign](https://bdsmovement.net/no-tech-oppression-apartheid-or-genocide)
([ADR-0002](adr/0002-screen-dependencies-against-bds-boycott-lists.md)). A PR
that adds a dependency or vendor adds its row.

Last checked against both lists on 2026-11-15.

| Dependency or vendor | Used for | Maintainer | On a list? | Decision |
|---|---|---|---|---|
| GitHub (repository, Actions, Dependabot, Projects) | Hosting the repository, CI, dependency updates and the project board | Microsoft | Yes | Free tier, industry standard, no viable alternative: allowed under the free-tool exception. Nothing is paid. |
| OpenTofu | Managing the zone's DNS and settings as code | OpenTofu project (Linux Foundation) | No | Allowed. Chosen over Terraform, whose owner IBM is a No Tech for Apartheid target. |
| Cloudflare Zero Trust Access and Turnstile | Signing in to admin sections and protecting forms from bots | Cloudflare, Inc. | No | Allowed |
