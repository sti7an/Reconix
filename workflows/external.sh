#!/usr/bin/env bash
# shellcheck shell=bash
# External perimeter recon

workflow_external() {
    local domain="$1"
    recon_require_args 1 "$@" || return 1
    workflow_phase1_recon "$domain"
    cd "$domain" 2>/dev/null && workflow_phase2_enumeration "$domain"
}
