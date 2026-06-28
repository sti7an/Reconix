#!/usr/bin/env bash
# shellcheck shell=bash

waybackurls_fetch() {
    local domain="$1" out="${2:-waybackurls.out}"
    recon_validate_domain "$domain" || return 1
    recon_require_tool waybackurls || return 1
    waybackurls "$domain" | sort -u --version-sort | tee "$out"
}

wayback_js() {
    local domain="$1" out="${2:-wayback_jsfiles.txt}"
    waybackurls_fetch "$domain" wayback.tmp
    grep -E '\.js($|\?)' wayback.tmp | sort -u | tee "$out"
    rmf wayback.tmp
}

_waybackurls() { waybackurls_fetch "$@"; }
