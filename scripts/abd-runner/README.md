# abd-runner: GitHub Actions runners on the Mac mini

Runs `RUNNER_COUNT` single-use GitHub Actions runners (`abd/github-runner`, built in `abd-cloud-containers`) side by side on `abd-dev-001` under the service account `svc-ghrunner`, and keeps the `RUNNER_HEARTBEAT` organisation variable fresh so workflows fall back to GitHub-hosted runners when the Mac mini is down. Rulings: `abd-cloud-containers` WP-03, ruling 22.

Follows the machine conventions in Tulox's `docs/runbooks/setup/dev-server-setup/` (base doc sections 1 and 5a; the `svc-mflux` and `svc-colima` roles): hidden `svc-` account, no auto-login, every service a LaunchDaemon with `UserName`, files placed with `install`.

## Design: one shared engine, a private engine per slot

The runners use the Mac mini's one Colima VM, `svc-colima`'s shared engine (`com.abd.colima`), which also runs the dev stack. (Until 2026-11-11 they had a VM of their own; two VMs next to mflux exhausted the 16 GB.)

Jobs never use the shared engine directly. Each slot is two containers on it:

| Container | What it is |
|---|---|
| `abd-runner-dind-<n>` | The slot's private Docker engine (`docker:dind`, privileged). A job's containers, `services:`, networks, volumes and image builds all live here, so a job cannot see or touch the dev stack or the other slot. Its `/var/lib/docker` is a volume, so image layers stay cached between jobs |
| `abd-runner-<n>` | The runner. It talks only to its slot's engine (a socket in a shared volume) and shares that engine's network, so ports a job publishes answer on `127.0.0.1` as on a hosted runner, and the two slots can never clash on a port |

Memory and CPU are capped per container (`DIND_*`, `RUNNER_*`). The engine's cap covers everything a job starts in it, so a runaway job is killed inside its slot rather than starving the dev stack. Between jobs the supervisor removes every container, network and volume in the slot's engine and empties its work folder; images stay, as cache.

## What runs

| Daemon (`/Library/LaunchDaemons/`) | Script | Schedule | Does |
|---|---|---|---|
| `com.abd.github-runner.supervise-<n>` | `abd-runner-supervise <n>` | KeepAlive, one per slot | Starts the slot's engine if needed, resets the slot, mints a just-in-time config through the GitHub App, runs one runner for one job, repeats |
| `com.abd.github-runner.heartbeat` | `abd-runner-heartbeat` | every 5 min | If a runner with our labels is online, writes the Unix time to `RUNNER_HEARTBEAT` |
| `com.abd.github-runner.prune` | `abd-runner-prune` | daily 05:00 | Inside each slot's engine: dangling images and week-old build cache, every image above `PRUNE_AT_PERCENT` disk use. On the shared engine only our labelled stopped containers and superseded runner images; never a whole-engine prune |

`lib.sh` holds settings, the App JWT and the API helper. `install.sh` installs and removes the daemons.

## Layout on the Mac mini

| Path | Owner, mode | Holds |
|---|---|---|
| `/Users/svc-ghrunner/abd-runner/` | root, 755 | The scripts, copied by `install.sh`. Root-owned so the account cannot change its own code |
| `/Users/svc-ghrunner/etc/abd-runner.env` | svc-ghrunner, 600 | Settings (from `abd-runner.env.example`) |
| `/Users/svc-ghrunner/etc/github-app.pem` | svc-ghrunner, 400 | GitHub App private key |
| `/Users/svc-ghrunner/src/abd-cloud-containers/` | svc-ghrunner | Copy of the image repository, for building the runner image |
| `/Users/svc-ghrunner/Library/Logs/abd-runner/` | svc-ghrunner | One log per daemon |
| On the shared engine: image `abd/github-runner:host`; volumes `abd-runner-cache`, `abd-runner-docker-<n>`, `abd-runner-work-<n>`, `abd-runner-sock-<n>` | | The runner image; the shared Composer, npm and tool cache; per slot, its engine's data, its work folder (`/srv/abd-runner/work/<n>`) and its engine's socket |

Everything of ours on the shared engine carries the label `com.abd.github-runner`.

## Install

Run as `abd-admin` over ssh unless a step says otherwise. Prerequisites: the base setup and `svc-colima`'s shared engine (Tulox `dev-server-setup/colima/`) are in place, and Homebrew has `docker`, `docker-buildx`, `jq`, `git`, `gh` and `make`.

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

Record the UID and password in the password manager. Do not add it to sshd `AllowUsers` (administer it with `sudo -u svc-ghrunner -H`).

### 2. Docker CLI plugins for the account

The Homebrew `docker-buildx` plugin lives outside the CLI's default search path. Merge the setting into `~/.docker/config.json` rather than overwrite the file; safe to rerun at any point:

```bash
sudo -u svc-ghrunner -H bash -lc 'export PATH=/opt/homebrew/bin:$PATH; mkdir -p ~/.docker; f=~/.docker/config.json;
  [ -s "$f" ] || echo "{}" > "$f";
  jq ".cliPluginsExtraDirs = [\"/opt/homebrew/lib/docker/cli-plugins\"]" "$f" > "$f.new" && mv "$f.new" "$f"'
```

### 3. GitHub App (organisation settings, Developer settings, GitHub Apps, New)

- Webhook off. Only on this account.
- Organisation permissions: **Self-hosted runners: read and write**, **Variables: read and write**. No repository permissions.
- Install it on the organisation (the repository selection does not matter; it has no repository permissions). Note the App ID and the installation ID (the number at the end of the installation's settings URL).
- Generate a private key and download it to the laptop.

### 4. Runner group (organisation settings, Actions, Runner groups, New)

- Name `abd-dev-001`. Repository access: **Selected repositories**, private repositories only. Leave public repositories off: a self-hosted runner would let any fork PR run code on the Mac mini.
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

Fill in `GH_APP_ID`, `GH_APP_INSTALLATION_ID` and `RUNNER_GROUP_ID`. Check `RUNNER_COUNT` and the caps against Sizing.

### 7. Access to the shared engine

`svc-ghrunner` joins `docker-users`, the group `com.abd.colima-sock` gives the shared engine's socket to, as `svc-tulox` does:

```bash
sudo dseditgroup -o edit -a svc-ghrunner -t user docker-users
sudo -u svc-ghrunner -H bash -lc 'export PATH=/opt/homebrew/bin:$PATH;
  export DOCKER_HOST=unix:///Users/svc-colima/.colima/default/docker.sock;
  docker info --format "{{.ServerVersion}} {{.MemTotal}}"; docker buildx version'
```

Both must answer. Then raise the shared VM's memory for the slots (Sizing): in `/Users/svc-colima/bin/colima-daemon.sh` change `--memory 6` to `--memory 9`, and restart the engine at a moment that suits the dev stack:

```bash
sudo sed -i '' 's/--memory 6 /--memory 9 /' /Users/svc-colima/bin/colima-daemon.sh
sudo launchctl kickstart -k system/com.abd.colima
# then, once docker info answers for 30 seconds:
sudo launchctl kickstart -k system/com.tulox.dev-stack
```

### 8. Runner image

Built from `main` of `abd-cloud-containers`, as `svc-ghrunner`, on the shared engine. Tagged `host` by hand, so no pull request can change the runner it runs on.

```bash
cd ~/Projects/abd-cloud-containers && git switch main && git pull
sudo rsync -a --delete ./ /Users/svc-ghrunner/src/abd-cloud-containers/
sudo chown -R svc-ghrunner:staff /Users/svc-ghrunner/src
sudo -u svc-ghrunner -H bash -lc 'export PATH=/opt/homebrew/bin:$PATH;
  export DOCKER_HOST=unix:///Users/svc-colima/.colima/default/docker.sock;
  cd ~/src/abd-cloud-containers &&
  make build IMAGE=base && make build IMAGE=php PHP=8.5 TARGET=dev &&
  make build IMAGE=github-runner && make test IMAGE=github-runner &&
  docker tag abd/github-runner:$(sed -n "s/^ARG RUNNER_VERSION=//p" images/github-runner/Dockerfile) abd/github-runner:host'
```

Once WP-02 has ECR, pull the pushed image by digest and tag that instead.

### 9. Install the daemons

```bash
cd ~/Projects/abd-cloud/scripts/abd-runner
sudo ./install.sh
ls -l@ /Library/LaunchDaemons/com.abd.github-runner.*   # no @: no quarantine flag
```

`install.sh` refuses to run until `svc-ghrunner` is in `docker-users` (step 7).

### 10. Verify

```bash
tail -f /Users/svc-ghrunner/Library/Logs/abd-runner/supervise-1.log   # "starting abd-runner-dind-1", then "slot 1: runner N registered"
tail /Users/svc-ghrunner/Library/Logs/abd-runner/heartbeat.log       # "heartbeat <time> (2 runner(s) online)"
sudo -u svc-ghrunner -H bash -lc 'export DOCKER_HOST=unix:///Users/svc-colima/.colima/default/docker.sock PATH=/opt/homebrew/bin:$PATH;
  docker ps --filter label=com.abd.github-runner --format "{{.Names}} {{.Status}}"'   # 2 engines, 2 runners
gh api orgs/AnalysisByDesign/actions/runners --jq '.runners[] | [.name, .status, .busy] | @tsv'
```

Then run `abd-cloud-containers`' build workflow by hand: its `select` job should choose the self-hosted labels, and the jobs should run on `abd-abd-dev-001-<slot>-<time>` runners. While it runs, `docker ps` on the shared engine still shows only our four containers: the job's own containers are inside the slots.

### 11. Reboot test

```bash
sudo reboot
# from the laptop, with nobody logged in on the Mac mini, after a few minutes:
gh api orgs/AnalysisByDesign/actions/runners --jq '.runners[] | [.name, .status] | @tsv'
```

Both slots online and dev.tulox.uk up confirms the engine, the slots and the key all work headless, side by side.

## Sizing

`abd-dev-001` has 16 GB: the shared Colima VM, mflux running natively, and macOS. The VM holds the dev stack and the slots, so it is raised from 6 GB to **9 GB** for two slots (step 7), against the 12 GB two VMs used.

| Per slot | Cap | Holds |
|---|---|---|
| `DIND_MEMORY`, `DIND_CPUS` | 2 GB, 2 | MySQL and other `services:`, image builds |
| `RUNNER_MEMORY`, `RUNNER_CPUS` | 1.5 GB, 2 | The job's own steps: PHP and Pest, Node |

The caps are ceilings, not reservations; a Pest shard typically uses well under them. Watch `memory_pressure` and swap (`sysctl vm.swapusage`) during a Tulox Pest run while mflux is generating. If the Mac mini swaps, lower `RUNNER_COUNT` to 1 (and the VM to 7.5 GB) rather than starving the dev stack. A job that exceeds its slot's cap is killed inside the slot (exit 137), never anything outside it.

## Operate

```bash
sudo launchctl kickstart -k system/com.abd.github-runner.supervise-1   # replace slot 1's runner (and its engine if stopped)
sudo ./install.sh                     # after changing RUNNER_COUNT or updating the scripts
sudo ./install.sh remove              # stop and remove all the daemons; each slot's engine stops with it (volumes kept)
# reset a slot completely (daemons removed): its engine's data and work folder
sudo -u svc-ghrunner -H bash -lc 'export DOCKER_HOST=unix:///Users/svc-colima/.colima/default/docker.sock PATH=/opt/homebrew/bin:$PATH;
  docker volume rm abd-runner-docker-1 abd-runner-work-1 abd-runner-sock-1'
```

- **Fall back to hosted runners**: stop the daemons, or delete `RUNNER_HEARTBEAT`. Workflows switch once the heartbeat is 15 minutes old.
- **Upgrade the runner**: GitHub stops sending jobs to runners more than 30 days behind the latest release. Bump it in `abd-cloud-containers`, merge, then repeat step 8. Each slot picks up the new `host` image with its next job.
- **Upgrade the slot engine**: change `DIND_IMAGE`, then `sudo launchctl kickstart -k` each supervisor while its slot is idle; the engine restarts on the new image with its cache volume intact.
- **Rotate the App key**: generate a new key in the App, repeat step 5, delete the old key in the App.

## Backups

- `etc/abd-runner.env` and `etc/github-app.pem` (the key also goes in the password manager).
- Excluded: the image and every volume (all rebuildable).

## Security

- **Isolation is against accidents, not hostile code.** A job reaches only its slot's engine, so `docker ps`, `rm` and `prune` inside a job cannot reach the dev stack or the other slot. The slot's engine is privileged, though, so deliberately malicious code could break out to the shared VM, and from there to the dev stack. Acceptable because the runner group admits selected private repositories only, all pushed by one person, never public ones or forks.
- The shared VM mounts `svc-colima`'s home folder (Colima's default). `svc-ghrunner`'s home, with `~/etc`, is not mounted into any VM, so jobs cannot reach the App key.
- The App key is read only by `openssl` when minting a token. Runner containers get a single-use config, unset before the runner starts.
- Nothing listens on TCP: each slot's engine has a Unix socket only, readable by the runner's group.

## From the separate-VM layout (before 2026-11-11)

The first install gave the runners a Colima VM of their own, which with `svc-colima`'s VM and mflux exhausted the Mac mini's memory and kept the dev engine restarting. To move:

```bash
cd ~/Projects/abd-cloud/scripts/abd-runner && sudo ./install.sh remove   # if not already done
sudo -u svc-ghrunner -H bash -lc 'export PATH=/opt/homebrew/bin:$PATH; colima delete -f'   # the old VM and its 100 GB disk
sudo rm -rf /Users/svc-ghrunner/.colima /Users/svc-ghrunner/vm-share
cd ~/Projects/abd-cloud && git switch main && git pull
```

Then steps 6 (the settings file changed: refresh it from the example and fill in the three IDs again), 7, 8, 9, 10 and 11.
