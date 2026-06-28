#!/usr/bin/env bash
# shellcheck shell=bash
# Logging system with levels and file output

: "${RECON_LOG_FILE:=}"

_recon_log_level_num() {
    case "${1^^}" in
        DEBUG) echo 0 ;;
        INFO)  echo 1 ;;
        WARN|WARNING) echo 2 ;;
        ERROR) echo 3 ;;
        *)     echo 1 ;;
    esac
}

_recon_log_should_log() {
    local level="$1"
    local current="${LOG_LEVEL:-INFO}"
    [[ $(_recon_log_level_num "$level") -ge $(_recon_log_level_num "$current") ]]
}

_recon_log_write() {
    local level="$1"
    shift
    local msg="$*"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    local line="[${ts}] [${level}] ${msg}"

    if _recon_log_should_log "$level"; then
        case "${level^^}" in
            ERROR)   echo -e "${RT_RED:-}${line}${RT_CLEAR:-}" >&2 ;;
            WARN|WARNING) echo -e "${RT_YELLOW:-}${line}${RT_CLEAR:-}" >&2 ;;
            DEBUG)   [[ "${DEBUG:-false}" == "true" ]] && echo -e "${RT_CYAN:-}${line}${RT_CLEAR:-}" ;;
            *)       echo -e "${line}" ;;
        esac
    fi

    if [[ -n "${RECON_LOG_FILE:-}" ]]; then
        echo "$line" >> "$RECON_LOG_FILE"
    elif [[ -n "${RECON_LOG_DIR:-}" ]]; then
        mkdir -p "$RECON_LOG_DIR" 2>/dev/null || true
        echo "$line" >> "${RECON_LOG_DIR}/reconix.log"
    fi
}

recon_log_debug()   { _recon_log_write DEBUG "$@"; }
recon_log_info()    { _recon_log_write INFO "$@"; }
recon_log_warn()    { _recon_log_write WARN "$@"; }
recon_log_error()   { _recon_log_write ERROR "$@"; }

recon_log_success() {
    echo -e "${RT_BOLD:-}${RT_GREEN:-} [+]${RT_CLEAR:-} $*"
    _recon_log_write INFO "SUCCESS: $*"
}

recon_log_failure() {
    echo -e "${RT_BOLD:-}${RT_RED:-} [X]${RT_CLEAR:-} $*"
    _recon_log_write ERROR "FAILURE: $*"
}

recon_init_session_log() {
    local name="${1:-session}"
    mkdir -p "${RECON_LOG_DIR:-${RECONIX_ROOT}/logs}" 2>/dev/null || true
    RECON_LOG_FILE="${RECON_LOG_DIR:-${RECONIX_ROOT}/logs}/${name}-$(date '+%Y%m%d-%H%M%S').log"
    recon_log_info "Session log: ${RECON_LOG_FILE}"
}
