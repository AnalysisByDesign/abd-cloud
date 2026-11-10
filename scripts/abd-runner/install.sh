#!/usr/bin/env bash
# Installs (or reinstalls) the abd-runner LaunchDaemons. Run as the admin
# account from this directory:
#   sudo ./install.sh            install scripts and daemons, start them
#   sudo ./install.sh remove     stop and remove the daemons (files kept)
#
# Follows the dev-server-setup design rule: no auto-login, so every service
# is a LaunchDaemon that drops to its service account with UserName and sets
# HOME and PATH itself. Files are placed with install, never cp, so no
# quarantine flag reaches launchd.
#
# Layout (RUNNER_USER defaults to svc-ghrunner):
#   ~/abd-runner/             these scripts, root-owned (the account cannot edit them)
#   ~/etc/abd-runner.env      settings, 600 (create before installing)
#   ~/etc/github-app.pem      App private key, 400 (create before installing)
#   ~/vm-share/               empty; the only host folder the VM mounts
#   ~/Library/Logs/abd-runner/
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "run with sudo" >&2; exit 1; }

src="$(cd "$(dirname "$0")" && pwd)"
user="${RUNNER_USER:-svc-ghrunner}"
home="$(dscl . -read "/Users/${user}" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
[ -n "${home}" ] || { echo "no account ${user}" >&2; exit 1; }
daemons="${LAUNCH_DAEMONS:-/Library/LaunchDaemons}"
prefix=com.abd.github-runner
bin="${home}/abd-runner"
logs="${home}/Library/Logs/abd-runner"

# Remove every daemon of ours first, including slots above a lowered count.
for plist in "${daemons}/${prefix}".*.plist; do
    [ -e "${plist}" ] || continue
    launchctl bootout system "${plist}" 2>/dev/null || true
    rm -f "${plist}"
done
if [ "${1:-}" = remove ]; then
    echo "removed"
    exit 0
fi

env_file="${home}/etc/abd-runner.env"
for f in "${env_file}" "${home}/etc/github-app.pem"; do
    [ -f "${f}" ] || { echo "missing ${f} (README, steps 5 and 6)" >&2; exit 1; }
done
RUNNER_COUNT="$(HOME="${home}" bash -c '. "$1"; echo "${RUNNER_COUNT:-1}"' _ "${env_file}")"

install -d -o root -g wheel -m 755 "${bin}"
for f in lib.sh abd-runner-colima abd-runner-supervise abd-runner-heartbeat abd-runner-prune; do
    install -o root -g wheel -m 755 "${src}/${f}" "${bin}/${f}"
done
install -d -o "${user}" -g staff -m 700 "${home}/etc"
install -d -o "${user}" -g staff -m 755 "${home}/vm-share" "${home}/Library/Logs" "${logs}"
chown "${user}:staff" "${env_file}" "${home}/etc/github-app.pem"
chmod 600 "${env_file}"
chmod 400 "${home}/etc/github-app.pem"

keepalive="<key>RunAtLoad</key><true/><key>KeepAlive</key><true/><key>ThrottleInterval</key><integer>30</integer>"
# name|program and arguments|schedule-xml
jobs=("colima|abd-runner-colima|${keepalive}")
for slot in $(seq 1 "${RUNNER_COUNT}"); do
    jobs+=("supervise-${slot}|abd-runner-supervise ${slot}|${keepalive}")
done
jobs+=(
    "heartbeat|abd-runner-heartbeat|<key>RunAtLoad</key><true/><key>StartInterval</key><integer>300</integer>"
    "prune|abd-runner-prune|<key>StartCalendarInterval</key><dict><key>Hour</key><integer>5</integer><key>Minute</key><integer>0</integer></dict>"
)

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT
for job in "${jobs[@]}"; do
    IFS='|' read -r name program schedule <<<"${job}"
    read -r script args <<<"${program}"
    label="${prefix}.${name}"
    cat >"${tmp}/${label}.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>${label}</string>
  <key>UserName</key><string>${user}</string>
  <key>ProgramArguments</key><array><string>${bin}/${script}</string>${args:+<string>${args}</string>}</array>
  <key>EnvironmentVariables</key><dict>
    <key>HOME</key><string>${home}</string>
    <key>PATH</key><string>/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
  <key>WorkingDirectory</key><string>${home}</string>
  ${schedule}
  <key>StandardOutPath</key><string>${logs}/${name}.log</string>
  <key>StandardErrorPath</key><string>${logs}/${name}.log</string>
</dict>
</plist>
EOF
    plutil -lint "${tmp}/${label}.plist" >/dev/null
    install -o root -g wheel -m 644 "${tmp}/${label}.plist" "${daemons}/${label}.plist"
    launchctl bootstrap system "${daemons}/${label}.plist"
    launchctl enable "system/${label}"
    echo "installed ${label}"
done
echo "logs: ${logs}"
