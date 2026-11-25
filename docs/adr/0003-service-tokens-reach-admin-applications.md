# 3. Let service tokens reach named admin applications

## Status

Accepted

## Context

Every admin application let in one person, the owner, through one policy.
Engage now needs to read Climbing Logbook's usage figures from that
project's admin host on a daily schedule, with no one signed in
(oneloneraven/coraxia#13). Climbing Logbook's Worker accepts a service
token on its usage endpoint only (ADR-0041 in that repository).

## Decision

Access service tokens are declared in `infra/`, one per caller. Each lists the
admin applications it may reach, and each of those applications gets one
service-auth (`non_identity`) policy for its tokens, after the owner policy.
Access only gets a token past the login; the project's Worker decides which
routes it may use.

Tokens never expire, and are rotated by raising `client_secret_version`. A
token with an expiry would stop the daily job without warning, and replacing
it needs a deleting plan.

## Consequences

- An admin application is no longer owner-only at the Access layer. Each
  project's Worker must refuse service tokens on every route it doesn't name.
- A leaked secret works until it is rotated.
- The secret is a sensitive output, read from state, never from the apply log.
