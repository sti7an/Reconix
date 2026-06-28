#!/usr/bin/env bash
# shellcheck shell=bash

gau_fetch() {
    local domain="$1" out="${2:-gau.out}"
    recon_validate_domain "$domain" || return 1
    recon_require_tool gau || return 1
    gau --subs "$domain" | sort -u --version-sort | tee "$out"
}

gau_subdomains() {
    local domain="$1" out="${2:-gau_domains.out}"
    recon_validate_domain "$domain" || return 1
    recon_require_tool gau || return 1
    local ext
    ext="$(echo "$domain" | cut -d . -f 2-)"
    gau --subs "$domain" | cut -d / -f 3 | grep -oE "[A-Za-z0-9_.-]*\.${ext}" | sort -u | tee "$out"
}

gau_js() {
    local domain="$1" out="${2:-gau_jslink.txt}"
    gau_fetch "$domain" gau.tmp
    grep -E '\.js($|\?)' gau.tmp | sort -u | tee "$out"
    rmf gau.tmp
}

_gau() { gau_fetch "$@"; }
_gau_domains() { gau_subdomains "$@"; }
