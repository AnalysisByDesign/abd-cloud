# abd-runner host (Mac mini)

Runs one single-use GitHub Actions runner (`abd/github-runner`, built in `abd-cloud-containers`) on the Mac mini under Colima, and keeps the `RUNNER_HEARTBEAT` organisation variable fresh so workflows fall back to GitHub-hosted runners when it is down. Rulings: `abd-cloud-containers` WP-03, ruling 22.

| File | Role | launchd |
|---|---|---|
| `abd-runner-supervise` | Empties the work folder, mints a just-in-time config, runs one runner container, repeats | KeepAlive |
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
   cp abd-runner.env.example abd-runner.env   # fill in GH_APP_ID, GH_APP_INSTALLATION_ID
   ./install.sh
   ```

## Checks

```bash
tail -f ~/Library/Logs/abd-runner/supervise.log    # "runner N registered, waiting for a job"
tail ~/Library/Logs/abd-runner/heartbeat.log       # "heartbeat <time> (1 runner(s) online)"
gh api orgs/AnalysisByDesign/actions/variables/RUNNER_HEARTBEAT --jq .value
```

A workflow run's `select` job prints the heartbeat age and the runner it chose.

## Notes

- The App key only passes through a pipe into `openssl`; the runner container gets a single-use config, unset before the runner starts.
- Jobs reach Colima's engine through the socket, which is root on the VM. Acceptable for private repositories owned by one person; do not attach this runner group to public repositories.
- The runner container uses the VM's network (`--network host`), so ports published by jobs (smoke tests) answer on `127.0.0.1` inside the job, as on a hosted runner.
- The work folder (`/srv/abd-runner/work`) is a path inside the Colima VM, mounted at the same path in the runner container, so bind mounts made by jobs resolve. It is emptied before each job.
- Upgrading the runner: rebuild and retag `host`; the next job picks it up.
