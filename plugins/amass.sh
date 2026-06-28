#!/usr/bin/env bash
# shellcheck shell=bash

amass_passive() {
    local domain="$1" out="${2:-amass.out}"
    recon_validate_domain "$domain" || return 1
    recon_require_tool amass || return 1
    amass enum -passive -d "$domain" -o "$out"
}

amass_active() {
    local domain="$1" out="${2:-amass.out}"
    recon_validate_domain "$domain" || return 1
    recon_require_tool amass || return 1
    local config="${AMASS_CONFIG:-${HOME}/.config/amass/config.ini}"
    local args=(-d "$domain" -o "$out")
    [[ -f "$config" ]] && args+=(-config "$config")
    amass enum "${args[@]}"
}

_amass() { amass_active "$@"; }
_amass_passive() { amass_passive "$@"; }
