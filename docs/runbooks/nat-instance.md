# Runbook: NAT Instance (WP-01)

**Applies to**: `abd-wordpress` account, VPC `abd-wordpress` (`10.240.0.0/21`, `vpc-00ae5d2141d9f2724`).
**Params target**: `abd-cloud-params/abd-wordpress/wordpress-vpc/nat-instance` (template `compute/ec2-asg`).
**Status**: prepared 2026-11-11, not yet applied.

All commands assume the repo root of `abd-cloud` and the `abd_global` aws-vault profile. CLI commands against the account need the `terraform` role in `800653036500` (or a profile for it).

## How it works

Private subnets send `0.0.0.0/0` to whichever instance last claimed the route. Nothing is pinned: no static ENI and no Elastic IP. The instance has an auto-assigned (floating) public IP.

The route tables an ASG manages come from `managed_route_table_azs` in its tfvars. Terraform resolves each AZ to the `abd-wordpress-private-<az>` route table at plan time, then passes the IDs to the user data and the ARNs to the IAM policy. The instance can change only those tables, and the plan shows exactly which ones.

On boot, each NAT instance stays in `Pending:Wait` (the `nat-route-flip` launch hook) while it runs `nat-instance/files/nat-route-flip.sh` from user data:

1. Disables source/destination checking on itself.
2. Restarts fck-nat (no ENI configured, so it uses the primary interface) and waits for IP forwarding.
3. Checks its own internet egress.
4. Records the current `0.0.0.0/0` target of each managed route table.
5. Replaces `0.0.0.0/0` in each managed route table so that it points at itself. This is the **route flip**.
6. Completes the launch hook with `CONTINUE`, retrying up to 5 times. Only then does the ASG mark it InService.

If anything fails, the script completes the hook with `ABANDON` and the ASG terminates the instance. If the flip had started, the script first restores the targets recorded in step 4. A flip that fails partway, or a hook that can't be completed, therefore never leaves the routes pointing at an instance that is being thrown away. The script logs to `/var/log/nat-route-flip.log`.

The flip runs before the hook is completed so that InService always means "is carrying the traffic". If the order were reversed, a failed flip would leave a healthy-looking instance that carries no traffic, and a refresh would then terminate the old instance that still is.

**In-place refresh.** Instance refreshes use min 100 / max 110 healthy:
1. The replacement launches alongside the old instance and sets itself up completely in `Pending:Wait`.
2. It flips the routes and goes InService.
3. After the 60-second warmup, the ASG terminates the old instance.
4. The `nat-drain` hook holds the old instance in `Terminating:Wait` for 120 seconds (nothing completes it, so it defaults to `CONTINUE`), then terminates it.

The old instance carries no new traffic once the routes have moved. **Draining doesn't keep connections open across a NAT swap.** The new instance has a different public IP and no connection-tracking state for flows that already exist. The client's next packet on a long-lived connection (an SMTP session, a long download, a websocket) now leaves through the new IP, and the remote end resets it. Short requests and anything that retries are unaffected. A NAT gateway replacement behaves the same way. The drain is cheap, so it stays.

Alarms notify `abd-alerts`:
- `abd-wordpress-nat-no-in-service-instances`: no InService instance for 3 minutes.
- `abd-wordpress-nat-status-check-failed`: an instance failing its EC2 status checks.

## Before the first apply

- [ ] The PRs are merged: abd-cloud `feat/nat-instance` and abd-cloud-params `feat/nat-instance`. Local checkouts are on `main` and pulled.
- [ ] abd-cloud #56 is merged, so `tf-run.sh` asks before applying. Otherwise **`apply` auto-approves**.
- [ ] You're subscribed to `abd-alerts` and have confirmed the email.
- [ ] A quiet time, never a Friday or Saturday evening.
- [ ] Note the current state so that rollback is obvious:
  ```bash
  aws ec2 describe-route-tables --filters Name=vpc-id,Values=vpc-00ae5d2141d9f2724 \
    --query 'RouteTables[].{Id:RouteTableId,Name:Tags[?Key==`Name`]|[0].Value,Target:Routes[?DestinationCidrBlock==`0.0.0.0/0`]|[0].[NatGatewayId,InstanceId]|[0]}' --output table
  ```
  Expected: the three `abd-wordpress-private-*` tables point at `nat-047a0c1aab3d1fee7`.

## Cutover (applying the NAT stack is the cutover)

1. Plan, and check that it creates the 14 resources and nothing else:
   ```bash
   aws-vault exec abd_global -- ./tf-run.sh -v ../abd-cloud-params/abd-wordpress/wordpress-vpc/nat-instance init
   aws-vault exec abd_global -- ./tf-run.sh ../abd-cloud-params/abd-wordpress/wordpress-vpc/nat-instance plan
   ```
2. Apply:
   ```bash
   aws-vault exec abd_global -- ./tf-run.sh ../abd-cloud-params/abd-wordpress/wordpress-vpc/nat-instance apply
   ```
   Terraform waits for the ASG to reach capacity, which includes the lifecycle hook. Expect a couple of minutes.
3. Watch the instance come up:
   ```bash
   aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names abd-wordpress-nat \
     --query 'AutoScalingGroups[0].Instances[].{Id:InstanceId,State:LifecycleState,Health:HealthStatus}' --output table
   ```
   `Pending:Wait` is normal while the script runs; then it should become `InService`. If it goes to `Terminating`, the script abandoned it: see "Troubleshooting".
4. Verify the routes now point at the instance (the describe-route-tables command above): the three private tables should show the NAT instance's ID.
5. Verify egress from the WordPress host through SSM Session Manager:
   ```bash
   aws ssm start-session --target <wordpress instance id>
   curl -s https://checkip.amazonaws.com    # should print the NAT instance's public IP, not 99.80.147.236
   ```
   Also check the sites, outbound mail (SES), and anything else that calls out (Stripe webhooks are inbound and unaffected).

## Manual instance refresh (the drill; repeat a few times before teardown)

A CLI-started refresh does **not** use Terraform's `instance_refresh` settings. Without explicit preferences it defaults to min 90 / max 100, which terminates first. Always pass the preferences:

```bash
aws autoscaling start-instance-refresh --auto-scaling-group-name abd-wordpress-nat \
  --preferences '{"MinHealthyPercentage":100,"MaxHealthyPercentage":110,"InstanceWarmup":60}'
aws autoscaling describe-instance-refreshes --auto-scaling-group-name abd-wordpress-nat \
  --query 'InstanceRefreshes[0].{Status:Status,Pct:PercentageComplete,Reason:StatusReason}'
```

While it runs, keep a loop going on the WordPress host to measure any gap:

```bash
while true; do printf '%s ' "$(date +%T)"; curl -s --max-time 3 https://checkip.amazonaws.com || echo FAIL; sleep 1; done
```

Expected: the printed IP changes to the new instance's IP with no `FAIL` lines, or only one or two.

## Rollback to the NAT gateway (while it still exists)

1. Stop new NAT instances from flipping the routes back:
   ```bash
   aws autoscaling update-auto-scaling-group --auto-scaling-group-name abd-wordpress-nat --min-size 0 --desired-capacity 0
   ```
2. Point the routes back at the gateway. Either:
   - with Terraform, which still manages the gateway routes until teardown:
     `aws-vault exec abd_global -- ./tf-run.sh ../abd-cloud-params/abd-wordpress/wordpress-vpc plan`, then `apply`. Expect 3 route updates plus the known RDS parameter group drift (see "Known noise").
   - or directly, for each private route table:
     `aws ec2 replace-route --route-table-id <rtb> --destination-cidr-block 0.0.0.0/0 --nat-gateway-id nat-047a0c1aab3d1fee7`
3. Verify with `checkip` from the WordPress host (`99.80.147.236`).

**Warning (until teardown)**: any apply of `wordpress-vpc` reverts the routes to the gateway, because `aws_route.private_nat_gateway` is still in its state. Do not apply `wordpress-vpc` after cutover unless you mean to roll back.

## Unplanned failure

If the NAT instance dies or fails its status checks, the ASG launches a replacement, which flips the routes when it boots. Private egress is down for the gap, typically a few minutes. This gap is accepted in WP-01. The alarms notify `abd-alerts`. Inbound web traffic through the ALB is unaffected; only outbound calls from private hosts fail during the gap.

## Teardown of the NAT gateway (when you are satisfied)

**Not yet coded, and needs a ruling.** Ruling 5 planned a `removed { lifecycle { destroy = false } }` block for the gateway routes. Terraform rejects a `removed` block while the resource is still declared, and `aws_route.private_nat_gateway` stays declared in the VPC template. The options:

- **A. `state rm`, then turn the gateway off** (recommended):
  ```bash
  aws-vault exec abd_global -- ./tf-run.sh ../abd-cloud-params/abd-wordpress/wordpress-vpc state rm \
    'aws_route.private_nat_gateway[0]' 'aws_route.private_nat_gateway[1]' 'aws_route.private_nat_gateway[2]'
  ```
  Then set `enable_nat_gateway = false` in `wordpress-vpc/vpc_config.tfvars`. The plan should show **only** `aws_nat_gateway.this[0]` and `aws_eip.nat[0]` being destroyed, and no routes.
- **B.** Remove the `aws_route.private_nat_gateway` resource from the VPC template and add the `removed` block. This is declarative, but the template then can no longer create gateway routes for any VPC.

**Never** set `enable_nat_gateway = false` while the routes are still in state: Terraform would delete the `0.0.0.0/0` routes the NAT instance owns (`DeleteRoute` matches on destination, not target) and cut private egress.

After teardown: the EIP `99.80.147.236` is released (ruling 6), and the rollback above no longer applies. To roll back after that, re-enable the gateway, then flip the routes back by hand.

## Scaling out (one NAT ASG per AZ)

The target is built so that it can be copied:
1. Copy `nat-instance` to one target per AZ, for example `nat-a`, `nat-b` and `nat-c`.
2. In each copy, set `name` (for example `nat-a`, which gives the ASG `abd-wordpress-nat-a`). Set `managed_route_table_azs` to that AZ alone, and `asg_availability_zones` to the same AZ, so the instance serves its own AZ without cross-AZ data charges.
3. Give each copy its own `statefile_basename` in its `nat_config.sh`, and its own sequence entry.
4. Remove the AZs from the original target, or retire it. **An AZ must never appear in two targets.** If it did, each target's instances would take the routes from the other on every launch. Terraform can't check this across targets.
Hook names are scoped to each ASG, so the copies can keep `nat-route-flip` and `nat-drain`. The ASG name, route table IDs and ARNs are derived automatically.

Trade-off: an ASG pinned to one AZ can't relaunch elsewhere if that AZ fails. Its private subnets are in the same AZ, though, so they'd be affected anyway.

## Troubleshooting

- **The instance cycles between `Pending:Wait` and `Terminating`**: the script is abandoning it. Connect with SSM Session Manager while it's in `Pending:Wait` (up to 300 seconds) and read `/var/log/nat-route-flip.log` and `journalctl -u fck-nat`. Things to check, none of which could be confirmed without a launch:
  - fck-nat uses the primary interface when `/etc/fck-nat.conf` is empty.
  - The AWS CLI is present (the script installs it with `dnf` if not).
  - IAM allows `ModifyInstanceAttribute` (tag condition) and `ReplaceRoute` (exact route table ARNs). Look for `UnauthorizedOperation` in the log.
- **The routes didn't move**: the log lists the route table IDs it was given and the target it found on each. Compare them with `route_table_ids` in the plan.
- **The routes went back to their old target**: the flip or the hook failed and the script rolled back. The cause is in the log, just above the `restoring` lines.

## Known noise

`wordpress-vpc` plans show an unrelated in-place change to `module.db-param-group[0].aws_db_parameter_group.this` (`apply_method` `pending-reboot` -> `immediate` for `max_allowed_packet` and `sql_mode`). It predates WP-01, and it appears on every plan. It isn't caused by the NAT work.
