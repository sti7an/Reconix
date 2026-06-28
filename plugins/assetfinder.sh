#!/usr/bin/env bash
# shellcheck shell=bash

assetfinder_subdomains() {
    local domain="$1" out="${2:-assetfinder.out}"
    recon_validate_domain "$domain" || return 1
    recon_require_tool assetfinder || return 1
    assetfinder --subs-only "$domain" | tee "$out"
}

_assetfinder() { assetfinder_subdomains "$@"; }
