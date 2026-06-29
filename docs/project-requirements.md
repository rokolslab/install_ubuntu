# Project Requirements

[Back to README](../README.md) | [Profiles](profiles.md) | [Quality Checks](12-quality-checks.md) | [Ready Rules](14-ready-rules.md)

## Purpose

`install_ubuntu` is a staged Ubuntu/VPS bootstrap project. It helps beginner Linux administrators and practical IT administrators prepare servers through visible, reviewable stages. It is not a blind one-command production installer.

## Scope

- Prepare Ubuntu/VPS hosts through documented stages.
- Keep security hardening, Docker setup, web/proxy setup, and AI stack setup profile-aware.
- Provide scripts and docs that are understandable before they are run.
- Prefer official Ubuntu and vendor documentation for system administration decisions.
- Keep risky system changes small, reviewable, verifiable, and reversible.

## Target Audience

- Beginner Linux administrators learning safe VPS operations.
- Practical IT administrators who need repeatable bootstrap steps.
- AI automation builders who need a documented Ubuntu base before running n8n, PostgreSQL with selected Supabase-related components, Redis, pgvector, monitoring, and backups.

## Supported Profiles

The governed profiles are `minimal`, `proxy`, `docker-host`, `web`, and `ai-stack`. Profile behavior and command order live in [VPS Profiles](profiles.md), [Scripts Catalog](scripts-catalog.md), and [Scripts Order](15-scripts-order.md).

Current project docs and claims must not imply full Supabase support. The current supported scope is PostgreSQL with selected Supabase-related components only where implemented: Supabase Postgres image, Supabase Meta, Supabase Studio, pgvector, PgBouncer, Redis and n8n.

## OS Baseline

- Ubuntu 24.04 LTS is the primary and priority baseline.
- Ubuntu 26.04 LTS is the next compatibility and validation target. It must be validated explicitly before being treated as fully supported.
- Newer Ubuntu LTS releases require explicit validation before docs or scripts claim support.

## Non-goals

These non-goals keep the project small and safe:

- No blind one-command production installation.
- No broad rewrites without evidence.
- No automatic installation of third-party proxy panels.
- No public exposure of internal databases, cache, dashboards, or automation tools by default.
- No full Supabase scope claim. Full Supabase implementation is out of scope unless approved as a future advanced phase.
- No exact package pinning policy inside setup docs; version policy belongs in [Version Policy](version-policy.md).

## Installation Philosophy

- Users choose a profile before running scripts.
- Each stage should explain what it changes and what to verify afterward.
- Public access defaults to SSH tunnel or Nginx/reverse proxy. Direct public Compose port publishing is an advanced explicit mode and must be reviewed separately.
- Beginner-facing docs should prefer links and short checklists over long command walls.

## Safety Principles

- Safe defaults are more important than convenience.
- Secrets must not be committed, printed unnecessarily, or written into tracked config files.
- Internal service ports remain local unless a reviewed public access path exists.
- Risky system changes must include verification and rollback.
- Privileged commands must be explicit and documented.

## Documentation Principles

- Keep `README.md` short as a landing page.
- Keep `QUICKSTART.md` focused on profile flows.
- Put detailed operational notes under `docs/`.
- Link to existing docs instead of duplicating setup instructions.
- Use beginner-friendly language and name risks clearly.

## Script Principles

- Scripts should be short, functional, and profile-aware.
- Top-level wrappers may orchestrate; component scripts should do one clear job.
- Scripts should fail clearly when required preconditions are missing.
- Scripts must not generate partial secrets when a canonical secrets generator is required.
- Script changes need read-only review, syntax checks, and profile-aware verification notes.

## Security Principles

- SSH, firewall, fail2ban, and updates are baseline security concerns.
- Do not open service ports automatically for `proxy` or internal stack services.
- Do not use `latest` container tags.
- Avoid exact apt pins by default; use official Ubuntu LTS repositories unless a vendor repository is justified.
- Every public access change needs an explicit reason, verification, and rollback.

## Quality Gates

These quality gates define readiness for changes:

- `git diff --check` passes.
- Bash syntax checks pass for changed shell scripts, when scripts are changed.
- `shellcheck` is used when available for touched shell scripts.
- Profile docs and acceptance criteria stay consistent.
- Clean Ubuntu 24.04 VM smoke-test evidence is required before release readiness claims.
- Ubuntu 26.04 compatibility claims require separate validation evidence.

## Change-control Rules

The change-control baseline is:

- One PR should solve one bounded problem.
- Prefer small PR-sized changes.
- Do read-only review before implementation when scope or safety risk is non-trivial.
- Implement only after human approval for governance, security, public access, or install-flow changes.
- Do not run install scripts, privileged commands, or containers during planning or review.
- Do not broaden scope into Supabase, public Compose override, CI, changelog, or version enforcement unless that is the approved PR goal.

## Links To Related Docs

- [Quick Start](../QUICKSTART.md)
- [System Requirements](../requirements/system-requirements.md)
- [VPS Profiles](profiles.md)
- [Scripts Catalog](scripts-catalog.md)
- [Scripts Order](15-scripts-order.md)
- [Quality Checks](12-quality-checks.md)
- [Ready Rules](14-ready-rules.md)
- [Version Policy](version-policy.md)
- [Acceptance Criteria](acceptance-criteria.md)
