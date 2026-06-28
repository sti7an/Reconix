#!/usr/bin/env bash
# shellcheck shell=bash
# subfinder plugin wrapper

subfinder_passive() {
    local domain="$1" out="${2:-subfinder.out}"
    recon_validate_domain "$domain" || return 1
    recon_require_tool subfinder || return 1
    subfinder -silent -d "$domain" -o "$out"
}

subfinder_all() {
    local domain="$1" out="${2:-subfinder.out}"
    recon_validate_domain "$domain" || return 1
    recon_require_tool subfinder || return 1
    subfinder -d "$domain" -all -o "$out"
}

_subfinder() { subfinder_passive "$@"; }
