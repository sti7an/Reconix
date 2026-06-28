#!/usr/bin/env bash
# shellcheck shell=bash
# Bootstrap - load all core modules

_recon_bootstrap_root() {
    if [[ -z "${RECON_TOOLS_ROOT:-}" ]]; then
        RECON_TOOLS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    fi
    export RECON_TOOLS_ROOT
}

_recon_source_core() {
    local core_dir="${RECON_TOOLS_ROOT}/core"
    local f
    for f in colors config logger validator cache dependencies notifications utils; do
        # shellcheck disable=SC1090
        source "${core_dir}/${f}.sh"
    done
}

_recon_source_commands() {
    local cmd_dir="${RECON_TOOLS_ROOT}/commands"
    local f
    for f in dns recon http web cloud nmap nuclei exploits cracking reporting; do
        [[ -f "${cmd_dir}/${f}.sh" ]] && source "${cmd_dir}/${f}.sh"
    done
}

_recon_source_plugins() {
    local plug_dir="${RECON_TOOLS_ROOT}/plugins"
    local f
    for f in "${plug_dir}"/*.sh; do
        [[ -f "$f" ]] && source "$f"
    done
}

recon_bootstrap() {
    _recon_bootstrap_root
    _recon_source_core
    recon_load_config
    _recon_source_commands
    _recon_source_plugins
}

recon_bootstrap_core_only() {
    _recon_bootstrap_root
    _recon_source_core
    recon_load_config
}
