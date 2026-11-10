#!/usr/bin/env bash
# Shared by the abd-runner host scripts. Sourced, not run.
# Reads abd-runner.env next to this file (see abd-runner.env.example).

ABD_RUNNER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=abd-runner.env.example
. "${ABD_RUNNER_DIR}/abd-runner.env"

: "${GH_SCOPE:?}" "${RUNNER_IMAGE:?}" "${RUNNER_LABELS:?}" "${WORK_DIR:?}"
: "${RUNNER_GROUP_ID:=1}" "${HEARTBEAT_VAR:=RUNNER_HEARTBEAT}" "${CONTAINER_NAME:=abd-runner}"
export DOCKER_HOST

GH_API=https://api.github.com
export DOCKER_SOCK=/var/run/docker.sock

log() { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

# Short-lived JWT for the GitHub App. The private key is stored base64
# encoded in the login Keychain and only ever passes through a pipe.
gh_app_jwt() {
    : "${GH_APP_ID:?}" "${KEYCHAIN_SERVICE:?}"
    local now unsigned sig
    now="$(date +%s)"
    unsigned="$(printf '{"alg":"RS256","typ":"JWT"}' | b64url).$(printf '{"iat":%d,"exp":%d,"iss":"%s"}' \
        $((now - 60)) $((now + 540)) "${GH_APP_ID}" | b64url)"
    sig="$(printf '%s' "${unsigned}" | openssl dgst -sha256 -sign \
        <(security find-generic-password -s "${KEYCHAIN_SERVICE}" -w | base64 -d) | b64url)"
    printf '%s.%s' "${unsigned}" "${sig}"
}

# Installation token for the App. GH_TOKEN, if set, is used instead
# (testing only).
gh_token() {
    if [ -n "${GH_TOKEN:-}" ]; then
        printf '%s' "${GH_TOKEN}"
        return
    fi
    : "${GH_APP_INSTALLATION_ID:?}"
    curl -fsS -X POST \
        -H "Authorization: Bearer $(gh_app_jwt)" \
        -H "Accept: application/vnd.github+json" \
        "${GH_API}/app/installations/${GH_APP_INSTALLATION_ID}/access_tokens" | jq -er .token
}

# gh_api <token> <method> <path> [json-body]
gh_api() {
    local token="$1" method="$2" path="$3" body="${4:-}"
    curl -fsS -X "${method}" \
        -H "Authorization: Bearer ${token}" \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        ${body:+-d "${body}"} \
        "${GH_API}/${path}"
}
