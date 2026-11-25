# Threat model

What Coraxia protects, from whom, and how. Update it in the same PR as any
change that adds or moves a trust boundary ([coding standards](coding-standards.md#security)).

## The system

Describe the components, where each runs, and how data flows between them.

## Trust boundaries

| Boundary | Between | What crosses it | Controls |
|---|---|---|---|
| Service → admin application | A caller holding an Access service token (Engage's daily job) and a project's admin application | The token's client id and secret, as request headers | One token per caller, listed per application in `infra/`; Access lets it past the login only, and the project's Worker limits it to the routes it allows (Climbing Logbook: its usage endpoint, ADR-0041 there). The secret is a sensitive output, never printed in the public apply log |
| Release job → GitHub API | `release.yml` and the release GitHub App | Short-lived App token (Contents and Workflows: read and write) to push release tags and create releases | Token minted only in the release job and scoped to this repository; App installed on this repository only; private key held as a repository secret |

## Assets

| Asset | Why it matters |
|---|---|
| Service token secrets | Anyone holding one gets past Access on the applications its token lists |
| Release App private key | Anyone holding it can mint tokens that push tags and, through Workflows, change workflow files |

## Actors

| Actor | Capability | Motivation |
|---|---|---|
| Anonymous internet user | Any public request | Abuse, data access |
| Signed-in user | Their own account | Access to others' data |
| Compromised dependency | Code execution at install or runtime | Credential theft |
| Maintainer account takeover | Repository and platform access | Anything |

## Threats (STRIDE)

| Threat | Category | Mitigation | Status |
|---|---|---|---|
| Leaked service token used to reach an admin application | Spoofing | It gets past Access only on the applications its token lists, and the Worker accepts it on its allowed routes alone; rotate it with `client_secret_version`. It never expires, so a leak lasts until rotated | Accepted |
| | Tampering | | |
| | Repudiation | | |
| | Information disclosure | | |
| | Denial of service | | |
| Leaked release token or App key used to alter workflow files | Elevation of privilege | The Workflows permission is needed because GitHub refuses a tag whose commit's workflow files differ from the default branch's. Tokens last one hour and are minted only in the release job; the key is a repository secret; the App is installed on this repository only | Accepted |

## Known gaps

None recorded yet.
