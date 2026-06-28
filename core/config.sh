#!/usr/bin/env bash
# shellcheck shell=bash
# Configuration management - loads from ~/.config/recon-tools/config.env

: "${RECON_TOOLS_VERSION:=1.0.0}"
: "${RECON_TOOLS_ROOT:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

_recon_config_paths() {
    RECON_USER_CONFIG="${XDG_CONFIG_HOME:-${HOME}/.config}/recon-tools/config.env"
    RECON_PROJECT_CONFIG="${RECON_TOOLS_ROOT}/config/config.env"
    RECON_DEFAULTS="${RECON_TOOLS_ROOT}/config/defaults.env"
    RECON_API_KEYS="${RECON_TOOLS_ROOT}/config/api_keys.env"
    RECON_TOOLS_CONF="${RECON_TOOLS_ROOT}/config/tools.conf"
}

_recon_load_env_file() {
    local file="$1"
    [[ -f "$file" ]] || return 0
    # shellcheck disable=SC1090
    set -a
    source "$file"
    set +a
}

recon_load_config() {
    _recon_config_paths

    _recon_load_env_file "$RECON_DEFAULTS"
    _recon_load_env_file "$RECON_PROJECT_CONFIG"
    _recon_load_env_file "$RECON_USER_CONFIG"
    _recon_load_env_file "$RECON_API_KEYS"

    # Paths
    : "${RECON_OUTPUT_DIR:=${DEFAULT_OUTPUT_DIR:-${RECON_TOOLS_ROOT}/output}}"
    : "${RECON_CACHE_DIR:=${RECON_TOOLS_ROOT}/cache}"
    : "${RECON_LOG_DIR:=${RECON_TOOLS_ROOT}/logs}"
    : "${RECON_TOOLS_DIR:=${TOOLS_DIR:-${HOME}/tools}}"
    : "${RECON_WORDLISTS_DIR:=${RECON_TOOLS_ROOT}/data/wordlists}"
    : "${RECON_RESOLVERS_FILE:=${RECON_TOOLS_ROOT}/data/resolvers/resolvers.txt}"
    : "${RECON_NUCLEI_TEMPLATES:=${NUCLEI_TEMPLATES:-${RECON_TOOLS_DIR}/nuclei-templates}}"

    # Defaults
    : "${DEFAULT_THREADS:=50}"
    : "${DEFAULT_TIMEOUT:=10}"
    : "${LOG_LEVEL:=INFO}"
    : "${DEBUG:=false}"
    : "${DRY_RUN:=false}"
    : "${INTERACTIVE:=true}"
    : "${MAX_RETRIES:=3}"
    : "${RETRY_BACKOFF:=2}"
    : "${MAX_PARALLEL:=4}"
    : "${BUG_BOUNTY_HEADER:=x-bug-bounty: hacker}"

    # VPS / remote (no hardcoded values)
    : "${VPS_IP:=}"
    : "${VPS_USER:=}"
    : "${VPS_SSH_KEY:=${HOME}/.ssh/id_rsa}"
    : "${VPS_WORK_DIR:=~/work/corps}"
    : "${CORP_ROOT_DIR:=${HOME}/work/corps}"

    # API keys (must be set by user)
    : "${TELEGRAM_TOKEN:=}"
    : "${TELEGRAM_CHAT_ID_RECON:=}"
    : "${TELEGRAM_CHAT_ID_SCRIPTS:=}"
    : "${GITHUB_TOKEN:=}"
    : "${SHODAN_API_KEY:=}"
    : "${CENSYS_API_ID:=}"
    : "${CENSYS_API_SECRET:=}"
    : "${IPINFO_TOKEN:=}"
    : "${SECURITYTRAILS_API_KEY:=}"
    : "${CHAOS_API_KEY:=}"
    : "${SLACK_WEBHOOK_URL:=}"
    : "${DISCORD_WEBHOOK_URL:=}"
    : "${MATTERMOST_WEBHOOK_URL:=}"
    : "${NOTIFY_LEVEL:=INFO}"

    mkdir -p "$RECON_OUTPUT_DIR" "$RECON_CACHE_DIR" "$RECON_LOG_DIR" 2>/dev/null || true
}

recon_require_var() {
    local name="$1"
    local value="${!name:-}"
    if [[ -z "$value" ]]; then
        recon_log_error "Required configuration variable '${name}' is not set."
        recon_log_error "Set it in: ${XDG_CONFIG_HOME:-${HOME}/.config}/recon-tools/config.env"
        return 1
    fi
}

recon_require_vars() {
    local var failed=0
    for var in "$@"; do
        recon_require_var "$var" || failed=1
    done
    return "$failed"
}

recon_config_show() {
    recon_load_config
    cat <<EOF
recon-tools v${RECON_TOOLS_VERSION}
  RECON_TOOLS_ROOT    = ${RECON_TOOLS_ROOT}
  RECON_USER_CONFIG   = ${RECON_USER_CONFIG}
  RECON_OUTPUT_DIR    = ${RECON_OUTPUT_DIR}
  RECON_TOOLS_DIR     = ${RECON_TOOLS_DIR}
  DEFAULT_THREADS     = ${DEFAULT_THREADS}
  DEFAULT_TIMEOUT     = ${DEFAULT_TIMEOUT}
  LOG_LEVEL           = ${LOG_LEVEL}
  VPS_IP              = ${VPS_IP:-<not set>}
  GITHUB_TOKEN        = ${GITHUB_TOKEN:+<set>}
  SHODAN_API_KEY      = ${SHODAN_API_KEY:+<set>}
  TELEGRAM_TOKEN      = ${TELEGRAM_TOKEN:+<set>}
EOF
}
