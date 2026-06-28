#!/usr/bin/env bash
# shellcheck shell=bash
# Color definitions - single source of truth

if [[ -z "${RECON_COLORS_LOADED:-}" ]]; then
    readonly RECON_COLORS_LOADED=1

    if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
        readonly RT_CLEAR="$(tput sgr0 2>/dev/null || echo '')"
        readonly RT_BOLD="$(tput bold 2>/dev/null || echo '')"
        readonly RT_RED="$(tput setaf 1 2>/dev/null || echo '')"
        readonly RT_GREEN="$(tput setaf 2 2>/dev/null || echo '')"
        readonly RT_YELLOW="$(tput setaf 3 2>/dev/null || echo '')"
        readonly RT_BLUE="$(tput setaf 4 2>/dev/null || echo '')"
        readonly RT_PURPLE="$(tput setaf 5 2>/dev/null || echo '')"
        readonly RT_CYAN="$(tput setaf 6 2>/dev/null || echo '')"
    else
        readonly RT_CLEAR=''
        readonly RT_BOLD=''
        readonly RT_RED=''
        readonly RT_GREEN=''
        readonly RT_YELLOW=''
        readonly RT_BLUE=''
        readonly RT_PURPLE=''
        readonly RT_CYAN=''
    fi

    # Legacy aliases for migrated functions
    clear="${RT_CLEAR}"
    bold="${RT_BOLD}"
    red="${RT_RED}"
    green="${RT_GREEN}"
    yellow="${RT_YELLOW}"
    blue="${RT_BLUE}"
    purple="${RT_PURPLE}"
    cyan="${RT_CYAN}"
fi
