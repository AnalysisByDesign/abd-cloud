# WP-02: Codified ECR and CI Push Access

**Repository**: `abd-cloud`
**Depends on**: nothing (can run in parallel with WP-01).
**Blocks**: WP-03 (somewhere to push to), WP-04, WP-05, and the Tulox package.
**Protocol**: Discovery, then Clarify (stop), then Build. See the programme overview.

## Why

Images need a home, and GitHub Actions needs to push to it without long-lived keys. There is an existing Terraform ECR module plus a manually created Tulox POC repository. This package builds a fresh, codified set; retiring the POC repository is a separate final step, once nothing pulls from it.

## Settled

- ECR in eu-west-1, created in Terraform.
- GitHub Actions authenticates through OIDC, with a role per consuming repository scoped to its own ECR repositories.
- The POC repository is left untouched by this package.

## Phase 1: Discovery

1. The existing ECR module: inputs, lifecycle policy support, tag mutability, scanning, encryption, cross-account or repository policy support, and callers.
2. The manual POC repository: its name, what pushes to it and what pulls from it today (CI workflows, launch templates, scripts in `abd-cloud-packer`).
3. Whether a GitHub OIDC provider and any GitHub Actions roles already exist, and how they are scoped.
4. How the account's existing roles and policies are named and tagged.

## Phase 2: Clarify (minimum questions)

- **Repository naming**: a namespace such as `abd/base`, `abd/php`, `abd/laravel`, `abd/wordpress`, then `abd/wp-<site>` and `tulox/app`, or a different scheme.
- **Tag policy**: immutable tags (recommended, so a tag always means one image) with a moving `latest` avoided, or mutable.
- **Lifecycle**: for example, expire untagged images after 7 days and keep the last 30 tagged images per repository. Nightly builds produce about 30 images a month per repository, so retention drives storage cost.
- **ECR pull-through cache** for Docker Hub (the official Valkey, MySQL and Debian images): it is free apart from storage and avoids Docker Hub rate limits. Adopt it or not?
- **Scanning**: basic scan on push (free) only, or more.
- Which GitHub repositories get push roles now: the images repository, `tulox`, and wherever the WordPress site manifests end up (see WP-05).

## Phase 3: Build scope

1. Extend the ECR module as needed, with new inputs defaulting to current behaviour.
2. Create the repositories and lifecycle policies per the rulings.
3. The OIDC provider (if absent) and per-repository push roles, scoped by `sub` claim to a repository and branch or environment.
4. A pull permission statement for the ECS execution role, which WP-04 attaches.
5. Outputs for repository URLs and role ARNs, so the consuming repositories and WP-04 can reference them.

## Out of scope

- Deleting or modifying the POC repository.
- Building or pushing any image.

## Done when

- The repositories exist with lifecycle policies applied.
- A test workflow in the images repository can authenticate through OIDC and push a throwaway image, and cannot push to another repository's namespace.
