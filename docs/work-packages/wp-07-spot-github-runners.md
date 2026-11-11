# WP-07: Self-Hosted GitHub Runners on Spot (Parked)

**Repository**: `abd-cloud`
**Status**: **Parked.** Reopen only when the free GitHub Actions minutes run out, consistent with the September deferral. This document records the design so WP-04 does not close off the option.
**Depends on**: WP-01, WP-02, WP-04.

## Settled design

- A **separate ECS cluster** for runners with its own **spot-only ASG**, `min = 0`. It is never shared with production hosts, IAM roles or capacity providers, because a runner executes pull request code and image builds need Docker access close to root on the host.
- It shares the VPC, the NAT instance and the S3 gateway endpoint (so ECR layer pulls avoid NAT data charges). Alternatively it runs in a public subnet with a public IP, which costs pennies while running. This is decided when the package reopens.
- The ECS-optimised AMI; nothing new to bake.
- **Scaling**: a small Lambda on GitHub's `workflow_job` webhook sets the desired count, and scales back to zero when idle. At this volume Lambda is free.
- Image builds use privileged mode or BuildKit on the EC2 host (not possible on Fargate).
- Zero cost while idle, apart from negligible Lambda and log storage.

## What WP-04 must not preclude

- The ASG module extensions support a spot-only, scale-to-zero configuration.
- Cluster and capacity provider resources are per-cluster, not hard-coded to `prod`.

## Open when reopened

- Ephemeral (one job per runner) or reusable runners.
- Org-level or repository-level registration, and how the runner token is issued (GitHub App recommended).
- Public subnet or NAT egress.
