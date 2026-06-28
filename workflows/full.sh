#!/usr/bin/env bash
# shellcheck shell=bash
# Full recon pipeline

workflow_full() {
    local domain="$1"
    recon_require_args 1 "$@" || return 1
    recon_validate_domain "$domain" || return 1
    recon_init_session_log "full-${domain}"

    local ws="${RECON_OUTPUT_DIR}/${domain}-full-$(date '+%Y%m%d')"
    mkdir -p "$ws" && cd "$ws" || return 1

    recon_log_info "=== Phase 1: Subdomains ==="
    recon_subdomains_no_brute "$domain"

    recon_log_info "=== Phase 2: Enumeration ==="
    cd "$domain" && recon_phase2 "$domain" "$domain"
    cd "$ws" || true

    recon_log_info "=== Phase 3: URL Collection ==="
    recon_urls "$domain"

    recon_log_info "=== Report ==="
    report_generate "$ws" "$domain"

    recon_notify INFO "Full recon for ${domain} complete"
    recon_log_success "Workspace: ${ws}"
}
