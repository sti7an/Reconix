#!/usr/bin/env bash
# shellcheck shell=bash

shuffledns_brute() {
    local domain="$1" wordlist="$2" out="${3:-shuffledns.out}"
    recon_validate_domain "$domain" || return 1
    recon_validate_file "$wordlist" "wordlist" || return 1
    recon_require_tool shuffledns || return 1
    local resolvers
    resolvers="$(_recon_resolvers 2>/dev/null)" || resolvers="/usr/share/seclists/Discovery/DNS/resolvers.txt"
    shuffledns -d "$domain" -w "$wordlist" -r "$resolvers" -o "$out"
}

_shuffledns() { shuffledns_brute "$@"; }
