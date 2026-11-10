#!/usr/bin/env bash
# Installs (or reinstalls) the abd-runner launchd agents for this user.
#   ./install.sh            install and start
#   ./install.sh remove     stop and remove
# Agents run in the logged-in user's session, which is where Colima and the
# login Keychain are, so the Mac mini needs automatic login.
set -euo pipefail

dir="$(cd "$(dirname "$0")" && pwd)"
agents="${HOME}/Library/LaunchAgents"
logs="${HOME}/Library/Logs/abd-runner"
prefix=uk.co.analysisbydesign.abd-runner
domain="gui/$(id -u)"

# name  script  schedule-xml
jobs=(
    "supervise|abd-runner-supervise|<key>RunAtLoad</key><true/><key>KeepAlive</key><true/><key>ThrottleInterval</key><integer>30</integer>"
    "heartbeat|abd-runner-heartbeat|<key>RunAtLoad</key><true/><key>StartInterval</key><integer>300</integer>"
    "prune|abd-runner-prune|<key>StartCalendarInterval</key><dict><key>Hour</key><integer>5</integer><key>Minute</key><integer>0</integer></dict>"
)

for job in "${jobs[@]}"; do
    IFS='|' read -r name _ _ <<<"${job}"
    launchctl bootout "${domain}/${prefix}.${name}" 2>/dev/null || true
    rm -f "${agents}/${prefix}.${name}.plist"
done
if [ "${1:-}" = remove ]; then
    echo "removed"
    exit 0
fi

[ -f "${dir}/abd-runner.env" ] || { echo "create ${dir}/abd-runner.env from abd-runner.env.example first" >&2; exit 1; }
mkdir -p "${agents}" "${logs}"

for job in "${jobs[@]}"; do
    IFS='|' read -r name script schedule <<<"${job}"
    plist="${agents}/${prefix}.${name}.plist"
    cat >"${plist}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>${prefix}.${name}</string>
  <key>ProgramArguments</key><array><string>${dir}/${script}</string></array>
  <key>EnvironmentVariables</key><dict>
    <key>PATH</key><string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
  ${schedule}
  <key>StandardOutPath</key><string>${logs}/${name}.log</string>
  <key>StandardErrorPath</key><string>${logs}/${name}.log</string>
</dict>
</plist>
EOF
    plutil -lint "${plist}" >/dev/null
    launchctl bootstrap "${domain}" "${plist}"
    echo "installed ${prefix}.${name}"
done
echo "logs: ${logs}"
