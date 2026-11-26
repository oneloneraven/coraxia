# Architecture decision records

Significant, hard-to-reverse decisions, one per file, in
[Nygard's format](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions):
Title, Status, Context, Decision, Consequences. Numbered `NNNN-title.md`.

An accepted ADR is never edited. A changed decision gets a new ADR, and the
old one's status becomes "Superseded by ADR-NNNN".

| ADR | Decision |
|---|---|
| 0001 | Record architecture decisions |
| 0002 | Screen dependencies and vendors against BDS boycott lists |
| 0003 | Let service tokens reach named admin applications |
| 0004 | Coraxia grants access, and brokers deploy credentials |

Every ADR is kept in the private vault, at `oneloneraven-vault/coraxia/adr/`. This index lists their numbers and titles only.
