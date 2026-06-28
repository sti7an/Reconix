#!/usr/bin/env bash
# shellcheck shell=bash
# Bug bounty focused workflow

workflow_bugbounty() {
    local domain="$1"
    recon_require_args 1 "$@" || return 1
    recon_validate_domain "$domain" || return 1
    recon_init_session_log "bugbounty-${domain}"

    local ws="${RECON_OUTPUT_DIR}/${domain}-bb-$(date '+%Y%m%d')"
    mkdir -p "$ws" && cd "$ws" || return 1

    recon_subdomains_no_brute "$domain"
    cd "$domain" 2>/dev/null || true
    recon_phase2 "$domain" "$domain"
    report_generate "$ws" "$domain"

    recon_notify INFO "Bug bounty recon for ${domain} complete: ${ws}"
}
