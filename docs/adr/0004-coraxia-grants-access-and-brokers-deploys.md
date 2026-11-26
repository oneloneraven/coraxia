# 4. Coraxia grants access, and brokers deploy credentials

## Status

Accepted.

## Context

One Lone Raven's central systems each have one job (project-bootstrap's [architecture](https://github.com/oneloneraven/project-bootstrap/blob/main/docs/architecture.md), its ADR-0008). Coraxia's job is to grant access, for people and machines.

Engage's deploy-credential broker (Engage's ADR-0008) grants access too, and its parent secret can mint any Cloudflare API token on the account. It lives in Engage, the system with the most code and the most public input. No repository uses it yet.

## Decision

- Coraxia keeps everything it manages in `infra/`: the Zero Trust organisation, the login method, the admin Access applications, Turnstile widgets and service tokens.
- **Coraxia gains a small Worker, the broker,** moved from Engage. It holds the parent token-minting secret and each repository's `token_policy`.
  - It mints a short-lived deploy credential for a GitHub Actions OIDC token only for a release Engage reports as approved.
  - That approval must carry the owner's Cloudflare Access token: signed by Access for the owner's email, for Engage's application, and issued in the last few minutes.
- **The long-lived deploy and infra apply tokens are then removed** from every repository, once their deploys are brokered.

## Consequences

- A compromised Engage can't mint a credential, because it can't forge the owner's Access token.
- Coraxia becomes running code as well as infrastructure, with its own deploy, tests and threat model.
- Every product deploy depends on coraxia's broker. A break-glass runbook covers deploying by hand.
- Guardian watches coraxia like any other system. Each minted token shows in Cloudflare's audit log.
