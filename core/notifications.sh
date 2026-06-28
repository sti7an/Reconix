#!/usr/bin/env bash
# shellcheck shell=bash
# Multi-channel notifications (Telegram, Slack, Discord, Mattermost)

_recon_notify_should_send() {
    local level="$1"
    local min="${NOTIFY_LEVEL:-INFO}"
    [[ $(_recon_log_level_num "$level") -ge $(_recon_log_level_num "$min") ]]
}

recon_notify_telegram() {
    local message="$1"
    local chat_id="${2:-${TELEGRAM_CHAT_ID_RECON:-}}"
    recon_require_var TELEGRAM_TOKEN || return 1
    [[ -n "$chat_id" ]] || { recon_log_error "Telegram chat_id required"; return 1; }

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        recon_log_info "[DRY-RUN] Telegram: ${message}"
        return 0
    fi

    curl -sf --max-time "${DEFAULT_TIMEOUT:-10}" \
        -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
        -d "chat_id=${chat_id}" \
        --data-urlencode "text=${message}" >/dev/null
}

recon_notify_slack() {
    local message="$1"
    [[ -n "${SLACK_WEBHOOK_URL:-}" ]] || return 1
    [[ "${DRY_RUN:-false}" == "true" ]] && { recon_log_info "[DRY-RUN] Slack: ${message}"; return 0; }
    curl -sf --max-time "${DEFAULT_TIMEOUT:-10}" \
        -X POST "${SLACK_WEBHOOK_URL}" \
        -H 'Content-Type: application/json' \
        -d "{\"text\":\"${message//\"/\\\"}\"}" >/dev/null
}

recon_notify_discord() {
    local message="$1"
    [[ -n "${DISCORD_WEBHOOK_URL:-}" ]] || return 1
    [[ "${DRY_RUN:-false}" == "true" ]] && { recon_log_info "[DRY-RUN] Discord: ${message}"; return 0; }
    curl -sf --max-time "${DEFAULT_TIMEOUT:-10}" \
        -X POST "${DISCORD_WEBHOOK_URL}" \
        -H 'Content-Type: application/json' \
        -d "{\"content\":\"${message//\"/\\\"}\"}" >/dev/null
}

recon_notify_mattermost() {
    local message="$1"
    [[ -n "${MATTERMOST_WEBHOOK_URL:-}" ]] || return 1
    [[ "${DRY_RUN:-false}" == "true" ]] && { recon_log_info "[DRY-RUN] Mattermost: ${message}"; return 0; }
    curl -sf --max-time "${DEFAULT_TIMEOUT:-10}" \
        -X POST "${MATTERMOST_WEBHOOK_URL}" \
        -H 'Content-Type: application/json' \
        -d "{\"text\":\"${message//\"/\\\"}\"}" >/dev/null
}

recon_notify() {
    local level="${1:-INFO}"
    local message="$2"
    _recon_notify_should_send "$level" || return 0

    recon_notify_telegram "$message" 2>/dev/null || true
    recon_notify_slack "$message" 2>/dev/null || true
    recon_notify_discord "$message" 2>/dev/null || true
    recon_notify_mattermost "$message" 2>/dev/null || true
}

# Legacy aliases
_tnotify_recon() { recon_notify INFO "$1"; }
_tnotify_script_hunter() { recon_notify INFO "$1" "${TELEGRAM_CHAT_ID_SCRIPTS:-${TELEGRAM_CHAT_ID_RECON:-}}"; }
