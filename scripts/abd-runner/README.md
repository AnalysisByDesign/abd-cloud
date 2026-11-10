# abd-runner host (Mac mini)

Runs `RUNNER_COUNT` single-use GitHub Actions runners (`abd/github-runner`, built in `abd-cloud-containers`) side by side on the Mac mini under Colima, and keeps the `RUNNER_HEARTBEAT` organisation variable fresh so workflows fall back to GitHub-hosted runners when it is down. Rulings: `abd-cloud-containers` WP-03, ruling 22.

| File | Role | launchd |
|---|---|---|
| `abd-runner-supervise <slot>` | Empties the slot's work folder, mints a just-in-time config, runs one runner container, repeats | KeepAlive, one per slot |
| `abd-runner-heartbeat` | If a runner with our labels is online, writes the Unix time to `RUNNER_HEARTBEAT` | every 5 min |
| `abd-runner-prune` | Removes stopped containers, dangling images and week-old build cache; all unused images only above `PRUNE_AT_PERCENT` disk use (never the runner image) | daily 05:00 |
| `lib.sh` | Config, App JWT and installation token, API helper | |
| `install.sh` | Writes the launchd agents and starts them; `install.sh remove` undoes it | |
| `abd-runner.env.example` | Settings; copy to `abd-runner.env` | |

Logs: `~/Library/Logs/abd-runner/`.

## One-time setup

1. **GitHub App** (org settings, Developer settings, GitHub Apps, New):
   - Webhook off. Installable only on this account.
   - Organisation permissions: **Self-hosted runners: read and write**, **Variables: read and write**. No repository permissions.
   - Install it on the organisation. Note the App ID and the installation ID (the number at the end of the installation's settings URL).
   - Generate a private key.
2. **Key into the Keychain** (on the Mac mini, then delete the download):
   ```bash
   security add-generic-password -U -s abd-github-runner-app -a abd-runner \
     -T /usr/bin/security -w "$(base64 -i ~/Downloads/<app>.private-key.pem)"
   rm ~/Downloads/<app>.private-key.pem
   ```
3. **Runner group**: the org's Default group must allow private repositories (it does by default). Public repositories stay excluded.
4. **Mac mini**: automatic login for the user that runs Colima (agents run in that session, which is also where the login Keychain is unlocked). Sleep off. Colima started at login (`brew services start colima`), with enough disk for image builds (`colima start --disk 100`).
5. **Runner image**: build from `main` of `abd-cloud-containers` and tag it for the host:
   ```bash
   make build IMAGE=base && make build IMAGE=github-runner
   docker tag abd/github-runner:<version> abd/github-runner:host
   ```
   Once WP-02 exists, pull the pushed image by digest and tag that instead.
6. **Install**:
   ```bash
   cp abd-runner.env.example abd-runner.env   # fill in GH_APP_ID, GH_APP_INSTALLATION_ID; RUNNER_COUNT
   ./install.sh
   ```

## Checks

```bash
tail -f ~/Library/Logs/abd-runner/supervise-1.log  # "slot 1: runner N registered, waiting for a job"
tail ~/Library/Logs/abd-runner/heartbeat.log       # "heartbeat <time> (2 runner(s) online)"
gh api orgs/AnalysisByDesign/actions/variables/RUNNER_HEARTBEAT --jq .value
```

A workflow run's `select` job prints the heartbeat age and the runner it chose.

## Notes

- The App key only passes through a pipe into `openssl`; the runner container gets a single-use config, unset before the runner starts.
- Jobs reach Colima's engine through the socket, which is root on the VM. Acceptable for private repositories owned by one person; do not attach this runner group to public repositories.
- The runner container uses the VM's network (`--network host`), so ports published by jobs (smoke tests, `services:` with `ports:`) answer on `127.0.0.1` inside the job, as on a hosted runner. All slots share that network, so jobs that can run at the same time must publish a random host port (`ports: [3306]`, then `${{ job.services.mysql.ports['3306'] }}`), not a fixed one (`3306:3306`).
- Work folders (`/srv/abd-runner/work/<slot>`) are paths inside the Colima VM, mounted at the same path in the runner container, so bind mounts made by jobs resolve. Each is emptied before its slot's next job.
- Shared caches: the `abd-runner-cache` volume is mounted at `/cache` in every runner, with `COMPOSER_CACHE_DIR`, `npm_config_cache` and `RUNNER_TOOL_CACHE` pointing into it. Every job and every repository shares it, which suits private repositories owned by one person. `docker volume rm abd-runner-cache` (with the agents stopped) starts it clean. Image layers and build cache are shared already, as every job uses the same engine.
- `RUNNER_COUNT`: each slot can run a full job (image builds, a MySQL service and a test suite), so size it to Colima's CPUs and memory (`colima start --cpu N --memory N`). Change it in `abd-runner.env` and rerun `./install.sh`.
- Upgrading the runner: rebuild and retag `host`; the next job picks it up.
