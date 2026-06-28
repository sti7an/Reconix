#!/usr/bin/env bash
# shellcheck shell=bash
# DNS and API result caching

_recon_cache_key() {
    echo -n "$1" | md5sum 2>/dev/null | awk '{print $1}' || echo -n "$1" | cksum | awk '{print $1}'
}

recon_cache_get() {
    local namespace="$1"
    local key="$2"
    local cache_dir="${RECON_CACHE_DIR}/${namespace}"
    local file="${cache_dir}/$(_recon_cache_key "$key")"
    local ttl="${3:-86400}"

    [[ -f "$file" ]] || return 1
    local age=$(( $(date +%s) - $(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || echo 0) ))
    [[ "$age" -le "$ttl" ]] || return 1
    cat "$file"
}

recon_cache_set() {
    local namespace="$1"
    local key="$2"
    local value="$3"
    local cache_dir="${RECON_CACHE_DIR}/${namespace}"
    mkdir -p "$cache_dir" 2>/dev/null || true
    printf '%s' "$value" > "${cache_dir}/$(_recon_cache_key "$key")"
}

recon_cache_clear() {
    local namespace="${1:-}"
    if [[ -z "$namespace" ]]; then
        rm -rf "${RECON_CACHE_DIR:?}"/* 2>/dev/null || true
        recon_log_info "Cache cleared"
    else
        rm -rf "${RECON_CACHE_DIR}/${namespace}" 2>/dev/null || true
        recon_log_info "Cache cleared for namespace: ${namespace}"
    fi
}

recon_cache_dns_resolve() {
    local domain="$1"
    local cached
    cached="$(recon_cache_get dns "$domain" 3600)" && { echo "$cached"; return 0; }
    local result
    result="$(dig +short A "$domain" 2>/dev/null | head -1)"
    [[ -n "$result" ]] && recon_cache_set dns "$domain" "$result"
    echo "$result"
}
