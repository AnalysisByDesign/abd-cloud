# abd-runner: GitHub Actions runners on the Mac mini

Runs `RUNNER_COUNT` single-use GitHub Actions runners (`abd/github-runner`, built in `abd-cloud-containers`) side by side on `abd-dev-001`, in their own Colima VM under the service account `svc-ghrunner`, and keeps the `RUNNER_HEARTBEAT` organisation variable fresh so workflows fall back to GitHub-hosted runners when the Mac mini is down. Rulings: `abd-cloud-containers` WP-03, ruling 22.

Follows the machine conventions in Tulox's `docs/runbooks/setup/dev-server-setup/` (base doc sections 1 and 5a; the `svc-mflux` and `svc-colima` roles): hidden `svc-` account, no auto-login, every service a LaunchDaemon with `UserName`, files placed with `install`.

## What runs

| Daemon (`/Library/LaunchDaemons/`) | Script | Schedule | Does |
|---|---|---|---|
| `com.abd.github-runner.colima` | `abd-runner-colima` | KeepAlive | The runner's own Colima VM. Separate from `svc-colima`'s shared engine, so jobs cannot see the dev stack |
| `com.abd.github-runner.supervise-<n>` | `abd-runner-supervise <n>` | KeepAlive, one per slot | Empties the slot's work folder, mints a just-in-time config through the GitHub App, runs one runner container for one job, repeats |
| `com.abd.github-runner.heartbeat` | `abd-runner-heartbeat` | every 5 min | If a runner with our labels is online, writes the Unix time to `RUNNER_HEARTBEAT` |
| `com.abd.github-runner.prune` | `abd-runner-prune` | daily 05:00 | Removes stopped containers, dangling images and week-old build cache; all unused images only above `PRUNE_AT_PERCENT` disk use (never the runner image) |

`lib.sh` holds settings, the App JWT and the API helper. `install.sh` installs and removes the daemons.

## Layout on the Mac mini

| Path | Owner, mode | Holds |
|---|---|---|
| `/Users/svc-ghrunner/abd-runner/` | root, 755 | The scripts, copied by `install.sh`. Root-owned so the account cannot change its own code |
| `/Users/svc-ghrunner/etc/abd-runner.env` | svc-ghrunner, 600 | Settings (from `abd-runner.env.example`) |
| `/Users/svc-ghrunner/etc/github-app.pem` | svc-ghrunner, 400 | GitHub App private key |
| `/Users/svc-ghrunner/vm-share/` | svc-ghrunner, 755, empty | The only host folder mounted into the VM (read-only) |
| `/Users/svc-ghrunner/src/abd-cloud-containers/` | svc-ghrunner | Copy of the image repository, for building the runner image |
| `/Users/svc-ghrunner/.colima/` | svc-ghrunner | The VM; its Docker socket is `.colima/default/docker.sock` |
| `/Users/svc-ghrunner/Library/Logs/abd-runner/` | svc-ghrunner | One log per daemon |
| Inside the VM: `/srv/abd-runner/work/<n>`, volume `abd-runner-cache` | | Work folder per slot (emptied before each job); shared Composer, npm and tool cache |

## Install

Run as `abd-admin` over ssh unless a step says otherwise. Prerequisites: the base setup is done, and Homebrew has `colima`, `docker`, `docker-buildx`, `jq`, `git`, `gh` and `make`.

### 0. GitHub access and checkouts

GitHub has no password auth on the Mac mini; `abd-admin` signs in with `gh` (device flow: open the URL on the laptop and enter the code). `setup-git` makes `gh` the credential helper, so plain `git pull` works too.

```bash
gh auth login --hostname github.com --git-protocol https --web
gh auth setup-git
mkdir -p ~/Projects
gh repo clone AnalysisByDesign/abd-cloud ~/Projects/abd-cloud
gh repo clone AnalysisByDesign/abd-cloud-containers ~/Projects/abd-cloud-containers
```

Only `abd-admin` holds a GitHub token. `svc-ghrunner` never gets one: it receives code through `sudo install` (step 9) and `sudo rsync` (step 8).

### 1. Service account

```bash
sudo sysadminctl -addUser svc-ghrunner -fullName "GitHub Runner Service" -password '<pwd>'
sudo dscl . create /Users/svc-ghrunner IsHidden 1
```

Record the UID and password in the password manager. Do not add it to `docker-users` (it has its own engine) or to sshd `AllowUsers` (administer it with `sudo -u svc-ghrunner -H`).

### 2. Docker CLI plugins for the account

The Homebrew `docker-buildx` plugin lives outside the CLI's default search path. Colima also writes to `~/.docker/config.json` (the `colima` context), so merge the setting in rather than overwrite the file; safe to rerun at any point:

```bash
sudo -u svc-ghrunner -H bash -lc 'export PATH=/opt/homebrew/bin:$PATH; mkdir -p ~/.docker; f=~/.docker/config.json;
  [ -s "$f" ] || echo "{}" > "$f";
  jq ".cliPluginsExtraDirs = [\"/opt/homebrew/lib/docker/cli-plugins\"]" "$f" > "$f.new" && mv "$f.new" "$f"'
```

Check after step 7: `docker buildx version` as `svc-ghrunner` must print a version, or step 8 fails with `unknown flag: --load`.

### 3. GitHub App (organisation settings, Developer settings, GitHub Apps, New)

- Webhook off. Only on this account.
- Organisation permissions: **Self-hosted runners: read and write**, **Variables: read and write**. No repository permissions.
- Install it on the organisation (the repository selection does not matter; it has no repository permissions). Note the App ID and the installation ID (the number at the end of the installation's settings URL).
- Generate a private key and download it to the laptop.

### 4. Runner group (organisation settings, Actions, Runner groups, New)

- Name `abd-dev-001`. Repository access: **Selected repositories**, starting with `abd-cloud-containers`; add `tulox` when its work package is picked up. Leave public repositories off.
- Note the group ID: `gh api orgs/AnalysisByDesign/actions/runner-groups --jq '.runner_groups[] | [.id, .name] | @tsv'` (needs `admin:org` on your `gh` token).

### 5. App key

```bash
scp ~/Downloads/<app>.private-key.pem abd-admin@abd-dev-001:/tmp/gh-app.pem   # from the laptop
sudo install -d -o svc-ghrunner -g staff -m 700 /Users/svc-ghrunner/etc
sudo install -o svc-ghrunner -g staff -m 400 /tmp/gh-app.pem /Users/svc-ghrunner/etc/github-app.pem
rm /tmp/gh-app.pem   # and the laptop download, once it is in the password manager
```

### 6. Settings

From an `abd-admin` checkout of `abd-cloud` (on the branch or tag to deploy):

```bash
cd ~/Projects/abd-cloud/scripts/abd-runner
sudo install -o svc-ghrunner -g staff -m 600 abd-runner.env.example /Users/svc-ghrunner/etc/abd-runner.env
sudo -u svc-ghrunner -H vi /Users/svc-ghrunner/etc/abd-runner.env
```

Fill in `GH_APP_ID`, `GH_APP_INSTALLATION_ID` and `RUNNER_GROUP_ID`. Check `RUNNER_COUNT` and the `COLIMA_*` sizing against section 12.

### 7. First Colima start, by hand

As for `svc-colima`: create the VM while you watch, before daemonising it.

```bash
sudo -u svc-ghrunner -H bash -lc 'export PATH=/opt/homebrew/bin:$PATH; mkdir -p ~/vm-share;
  colima start --cpu 4 --memory 6 --disk 100 --vm-type vz --mount ~/vm-share'
sudo -u svc-ghrunner -H bash -lc 'export PATH=/opt/homebrew/bin:$PATH; docker info --format "{{.ServerVersion}}";
  colima ssh -- ls /Users/svc-ghrunner'   # expect only vm-share: the home folder is not mounted
```

If vz will not boot, use `--vm-type qemu` and set `COLIMA_VM_TYPE=qemu` in the settings. Leave the VM running for step 8.

### 8. Runner image

Built from `main` of `abd-cloud-containers`, as `svc-ghrunner`, on the runner's engine. Tagged `host` by hand, so no pull request can change the runner it runs on.

```bash
cd ~/Projects/abd-cloud-containers && git switch main && git pull
sudo rsync -a --delete ./ /Users/svc-ghrunner/src/abd-cloud-containers/
sudo chown -R svc-ghrunner:staff /Users/svc-ghrunner/src
sudo -u svc-ghrunner -H bash -lc 'export PATH=/opt/homebrew/bin:$PATH; cd ~/src/abd-cloud-containers &&
  make build IMAGE=base && make build IMAGE=php PHP=8.5 TARGET=dev &&
  make build IMAGE=github-runner && make test IMAGE=github-runner &&
  docker tag abd/github-runner:$(sed -n "s/^ARG RUNNER_VERSION=//p" images/github-runner/Dockerfile) abd/github-runner:host'
```

Once WP-02 has ECR, pull the pushed image by digest and tag that instead.

### 9. Install the daemons

```bash
sudo -u svc-ghrunner -H bash -lc 'export PATH=/opt/homebrew/bin:$PATH; colima stop'
cd ~/Projects/abd-cloud/scripts/abd-runner
sudo ./install.sh
ls -l@ /Library/LaunchDaemons/com.abd.github-runner.*   # no @: no quarantine flag
```

### 10. Verify

```bash
sudo launchctl print system/com.abd.github-runner.supervise-1 | grep -E 'state|last exit'
tail -f /Users/svc-ghrunner/Library/Logs/abd-runner/supervise-1.log   # "slot 1: runner N registered, waiting for a job"
tail /Users/svc-ghrunner/Library/Logs/abd-runner/heartbeat.log       # "heartbeat <time> (2 runner(s) online)"
gh api orgs/AnalysisByDesign/actions/runners --jq '.runners[] | [.name, .status, .busy] | @tsv'
gh api orgs/AnalysisByDesign/actions/variables/RUNNER_HEARTBEAT --jq .value
```

Then run `abd-cloud-containers`' build workflow by hand: its `select` job should report the heartbeat age and choose the self-hosted labels, and the jobs should run on `abd-dev-001-...` runners.

### 11. Reboot test

```bash
sudo reboot
# from the laptop, with nobody logged in on the Mac mini, after a few minutes:
gh api orgs/AnalysisByDesign/actions/runners --jq '.runners[] | [.name, .status] | @tsv'
```

Both slots online confirms the VM, the supervisors and the key all work headless.

### 12. Sizing

`abd-dev-001` has 16 GB, shared with `svc-colima`'s VM (`--memory 6`) and mflux running natively. Each slot can run a full job: an image build, or a MySQL service plus a Pest run. Start with `COLIMA_CPU=4`, `COLIMA_MEMORY=6` and `RUNNER_COUNT=2`, and watch `memory_pressure` and swap (`sysctl vm.swapusage`) during a Tulox Pest run while mflux is generating. If it swaps, lower `RUNNER_COUNT` to 1 or the memory, rather than starving the dev stack. CPU and memory apply when the VM restarts; disk only grows.

## Operate

```bash
sudo launchctl kickstart -k system/com.abd.github-runner.colima        # restart the VM
sudo launchctl kickstart -k system/com.abd.github-runner.supervise-1   # replace slot 1's runner
sudo ./install.sh                     # after changing RUNNER_COUNT or updating the scripts
sudo ./install.sh remove              # stop and remove all the daemons (files kept)
sudo -u svc-ghrunner -H bash -lc 'export PATH=/opt/homebrew/bin:$PATH; docker volume rm abd-runner-cache'   # clear the shared cache (daemons stopped)
```

- **Fall back to hosted runners**: stop the daemons, or delete `RUNNER_HEARTBEAT`. Workflows switch once the heartbeat is 15 minutes old; `workflow_dispatch` with `runner: hosted` forces it for one run.
- **Upgrade the runner**: GitHub stops sending jobs to runners more than 30 days behind the latest release. Bump it in `abd-cloud-containers`, merge, then repeat step 8. Each slot picks up the new `host` image with its next job.
- **Rotate the App key**: generate a new key in the App, repeat step 5, delete the old key in the App.

## Backups

- `etc/abd-runner.env` and `etc/github-app.pem` (the key also goes in the password manager).
- Excluded: the VM, the cache volume and the image (all rebuildable).

## Security

- Jobs are root on the runner's VM through the Docker socket. Acceptable for private repositories owned by one person; the runner group admits selected private repositories only, never public ones or forks.
- The VM mounts only the empty `~/vm-share`, so jobs cannot reach `~/etc`. Colima mounts the whole home folder when no mount is given; keep the `--mount` in `abd-runner-colima`.
- The App key is read only by `openssl` when minting a token. Runner containers get a single-use config, unset before the runner starts.
- Runners run with `--network host` on the VM, so ports published by jobs answer on `127.0.0.1` inside the job, as on a hosted runner. Slots share that network: jobs that can run at the same time must publish a random host port (`ports: [3306]`, then `${{ job.services.mysql.ports['3306'] }}`), never a fixed one.
