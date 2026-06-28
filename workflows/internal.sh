#!/usr/bin/env bash
# shellcheck shell=bash
# Internal network discovery

workflow_internal() {
    local interface="${1:-eth0}"
    recon_init_session_log "internal-${interface}"
    discover_network "$interface"
    recon_log_success "Internal discovery complete"
}
