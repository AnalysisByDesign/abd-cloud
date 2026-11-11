#!/usr/bin/env bash
# Shared by the abd-runner host scripts. Sourced, not run.
# Reads ${ABD_RUNNER_ENV:-$HOME/etc/abd-runner.env} (see abd-runner.env.example).

ABD_RUNNER_ENV="${ABD_RUNNER_ENV:-${HOME}/etc/abd-runner.env}"
# shellcheck source=abd-runner.env.example
. "${ABD_RUNNER_ENV}"

: "${GH_SCOPE:?}" "${RUNNER_IMAGE:?}" "${RUNNER_LABELS:?}" "${WORK_ROOT:?}" "${DOCKER_HOST:?}"
: "${RUNNER_COUNT:=1}" "${RUNNER_GROUP_ID:=1}" "${HEARTBEAT_VAR:=RUNNER_HEARTBEAT}"
: "${CONTAINER_NAME:=abd-runner}" "${CACHE_VOLUME:=abd-runner-cache}"
: "${DIND_IMAGE:=docker:29.9.2-dind}" "${DIND_MEMORY:=2g}" "${DIND_CPUS:=2}"
: "${RUNNER_MEMORY:=1536m}" "${RUNNER_CPUS:=2}"
export DOCKER_HOST

GH_API=https://api.github.com

log() { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

# The shared engine is svc-colima's Colima. Colima restarts dockerd during
# its own start, so a socket that answers once is not ready (dev-server-setup base doc, 5a.3). Returns once
# `docker info` has succeeded continuously for 30 seconds.
wait_for_engine() {
    local stable=0
    while [ "${stable}" -lt 30 ]; do
        if docker info >/dev/null 2>&1; then
            stable=$((stable + 5))
        else
            [ "${stable}" -gt 0 ] && log "engine dropped; waiting again"
            stable=0
        fi
        sleep 5
    done
}

# Short-lived JWT for the GitHub App. The private key is a file readable
# only by the service account (GH_APP_KEY_FILE).
gh_app_jwt() {
    : "${GH_APP_ID:?}" "${GH_APP_KEY_FILE:?}"
    local now unsigned sig
    now="$(date +%s)"
    unsigned="$(printf '{"alg":"RS256","typ":"JWT"}' | b64url).$(printf '{"iat":%d,"exp":%d,"iss":"%s"}' \
        $((now - 60)) $((now + 540)) "${GH_APP_ID}" | b64url)"
    sig="$(printf '%s' "${unsigned}" | openssl dgst -sha256 -sign "${GH_APP_KEY_FILE}" | b64url)"
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
