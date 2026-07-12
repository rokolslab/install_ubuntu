# Version Policy

[Back to README](../README.md) | [Project Requirements](project-requirements.md) | [Quality Checks](12-quality-checks.md)

## Purpose

This policy defines how `install_ubuntu` documents and changes package, Docker, and application versions without making beginner setup brittle.

## Ubuntu Package Policy

- Ubuntu 24.04 LTS is the priority baseline for package and script validation.
- Ubuntu 26.04 LTS is the next compatibility target and must be validated separately.
- Use official Ubuntu LTS repositories for Ubuntu packages by default.
- Use package names and capabilities in docs instead of exact package versions unless a freeze is explicitly required.
- no exact apt package pins by default.

## Vendor Repository Policy

- A vendor repository is allowed only when the official Ubuntu LTS repository does not provide the required supported component.
- Vendor repositories must be official, documented, and installed with their signing key and repository configuration.
- The reason for each vendor repository must be documented near the install flow.

## Docker Engine And Docker Compose Plugin Policy

- Docker Engine and Docker Compose plugin should come from the official Docker stable apt repository.
- The install flow should follow Docker's official Ubuntu instructions for the validated Ubuntu baseline.
- Docker package changes must be verified on Ubuntu 24.04 before release claims.

## Exact Package Pinning Policy

- Exact apt package pins are not the beginner default.
- Exact Docker Engine version installation is an advanced freeze/rollback scenario only.
- If an exact package version is pinned, the PR must explain why, how to update it, and how to roll back.

## Compose Image Tag Policy

- Docker Compose images must use explicit version tags.
- `latest` is forbidden for Compose images.
- Each pinned application or container version needs an update procedure.
- Image version changes must not be mixed with unrelated script or firewall changes.

## Digest Pinning Policy

- digest pinning is optional production reproducibility mode, not the beginner default.
- If digest pinning is used, docs must explain how to refresh the digest and verify the new image.
- Digest pinning must not hide the human-readable application version tag in review context.

## Update Procedure

For every pinned app or container version:

1. Read the upstream changelog or release notes.
2. Update the version in the smallest possible PR.
3. Run static validation such as `docker compose config` where relevant.
4. Run smoke tests for affected services.
5. Document rollback notes when stateful services are affected.

## Version Bump Acceptance Criteria

- The PR states what changed and why.
- Review covers upstream changelog or release notes.
- smoke tests are listed and, when feasible, executed.
- Release notes or changelog update is included when the project starts maintaining release notes.
- Clean Ubuntu 24.04 evidence is required before release readiness claims.
- Ubuntu 26.04 compatibility evidence is required before compatibility claims.

## Emergency Security Update Procedure

- Security fixes may prioritize speed, but still require review of changed versions and affected services.
- Keep emergency updates narrow: version changes only unless a mitigation requires more.
- After the emergency change, capture follow-up work for smoke tests, rollback validation, and release notes.

## See Also

- [Project Requirements](project-requirements.md) — scope and governance baseline.
- [Acceptance Criteria](acceptance-criteria.md) — profile-level readiness gates.
- [Quality Checks](12-quality-checks.md) — local and CI validation commands.
