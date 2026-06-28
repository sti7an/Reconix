#!/usr/bin/env bash
# shellcheck shell=bash
# Input validation helpers

recon_validate_domain() {
    local domain="$1"
    [[ -n "$domain" ]] || { recon_log_error "Domain is required"; return 1; }
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        recon_log_error "Invalid domain format: ${domain}"
        return 1
    fi
}

recon_validate_ip() {
    local ip="$1"
    [[ -n "$ip" ]] || { recon_log_error "IP address is required"; return 1; }
    if [[ ! "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        recon_log_error "Invalid IP format: ${ip}"
        return 1
    fi
    local o
    IFS='.' read -r o1 o2 o3 o4 <<< "$ip"
    for o in "$o1" "$o2" "$o3" "$o4"; do
        [[ "$o" -le 255 ]] || { recon_log_error "Invalid IP octet: ${ip}"; return 1; }
    done
}

recon_validate_file() {
    local file="$1"
    local desc="${2:-file}"
    [[ -n "$file" ]] || { recon_log_error "${desc} path is required"; return 1; }
    [[ -f "$file" ]] || { recon_log_error "${desc} not found: ${file}"; return 1; }
}

recon_validate_dir() {
    local dir="$1"
    [[ -n "$dir" ]] || { recon_log_error "Directory path is required"; return 1; }
    [[ -d "$dir" ]] || { recon_log_error "Directory not found: ${dir}"; return 1; }
}

recon_validate_url() {
    local url="$1"
    [[ -n "$url" ]] || { recon_log_error "URL is required"; return 1; }
    [[ "$url" =~ ^https?:// ]] || { recon_log_error "Invalid URL (must start with http:// or https://): ${url}"; return 1; }
}

recon_require_args() {
    local min="$1"
    shift
    local got=$#
    if [[ "$got" -lt "$min" ]]; then
        recon_log_error "Expected at least ${min} argument(s), got ${got}"
        return 1
    fi
}

recon_confirm() {
    local msg="${1:-Are you sure?}"
    [[ "${INTERACTIVE:-true}" != "true" ]] && return 0
    [[ "${DRY_RUN:-false}" == "true" ]] && { recon_log_info "[DRY-RUN] Would confirm: ${msg}"; return 0; }
    local reply
    read -r -p "${msg} [y/N] " reply
    [[ "${reply,,}" == "y" || "${reply,,}" == "yes" ]]
}
