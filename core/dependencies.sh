#!/usr/bin/env bash
# shellcheck shell=bash
# Dependency detection and health checks

RECON_REQUIRED_TOOLS=(curl jq)
RECON_OPTIONAL_TOOLS=(
    subfinder amass httpx nuclei nmap massdns waybackurls gau unfurl assetfinder
    dnsgen shuffledns hakrawler gospider subjs ffuf wfuzz eyewitness aquatone gowitness
    hashcat john hashcat gobuster feroxbuster nuclei shodan dig host nslookup parallel
)

_recon_detect_os() {
    case "$(uname -s)" in
        Linux*)  RECON_OS="linux" ;;
        Darwin*) RECON_OS="macos" ;;
        *)       RECON_OS="unknown" ;;
    esac
}

recon_has_tool() {
    command -v "$1" >/dev/null 2>&1
}

recon_tool_version() {
    local tool="$1"
    case "$tool" in
        subfinder) subfinder -version 2>&1 | head -1 ;;
        nuclei)    nuclei -version 2>&1 | head -1 ;;
        nmap)      nmap --version 2>&1 | head -1 ;;
        jq)        jq --version 2>&1 ;;
        *)         "$tool" --version 2>&1 | head -1 || "$tool" -V 2>&1 | head -1 || echo "unknown" ;;
    esac
}

recon_check_tool() {
    local tool="$1"
    if recon_has_tool "$tool"; then
        recon_log_success "${tool} found: $(recon_tool_version "$tool")"
        return 0
    fi
    recon_log_failure "${tool} not found"
    return 1
}

recon_install_hint() {
    local tool="$1"
    _recon_detect_os
    case "$RECON_OS" in
        linux)
            case "$tool" in
                subfinder|httpx|nuclei|assetfinder|waybackurls|gau|unfurl|dnsgen|shuffledns)
                    echo "  go install github.com/projectdiscovery/${tool}/v2/cmd/${tool}@latest"
                    ;;
                jq) echo "  sudo apt install jq  # or: brew install jq" ;;
                nmap) echo "  sudo apt install nmap" ;;
                *)  echo "  See docs/INSTALL.md for ${tool}" ;;
            esac
            ;;
        macos)
            case "$tool" in
                jq) echo "  brew install jq" ;;
                nmap) echo "  brew install nmap" ;;
                *)  echo "  brew install ${tool}  # or go install" ;;
            esac
            ;;
        *) echo "  See docs/INSTALL.md" ;;
    esac
}

recon_check_dependencies() {
    local strict="${1:-false}"
    local missing=0
    recon_log_info "Checking required tools..."
    for tool in "${RECON_REQUIRED_TOOLS[@]}"; do
        recon_check_tool "$tool" || {
            recon_install_hint "$tool"
            missing=$((missing + 1))
        }
    done
    if [[ "$strict" == "true" && "$missing" -gt 0 ]]; then
        return 1
    fi
    return 0
}

recon_health_check() {
    local failed=0
    recon_log_info "=== Reconix health check v${RECONIX_VERSION} ==="

    recon_check_dependencies || failed=1

    recon_log_info "Checking optional recon tools..."
    local present=0 total=${#RECON_OPTIONAL_TOOLS[@]}
    for tool in "${RECON_OPTIONAL_TOOLS[@]}"; do
        recon_has_tool "$tool" && present=$((present + 1))
    done
    recon_log_info "Optional tools: ${present}/${total} installed"

    # Config validation
    [[ -n "${GITHUB_TOKEN:-}" ]]     && recon_log_success "GITHUB_TOKEN configured"     || recon_log_warn "GITHUB_TOKEN not set"
    [[ -n "${SHODAN_API_KEY:-}" ]]   && recon_log_success "SHODAN_API_KEY configured"   || recon_log_warn "SHODAN_API_KEY not set"
    [[ -n "${TELEGRAM_TOKEN:-}" ]]  && recon_log_success "TELEGRAM_TOKEN configured"  || recon_log_warn "TELEGRAM_TOKEN not set"
    [[ -n "${VPS_IP:-}" ]]           && recon_log_success "VPS_IP configured"           || recon_log_warn "VPS_IP not set (remote functions disabled)"

    # Network
    if curl -sf --max-time 5 https://api.github.com >/dev/null 2>&1; then
        recon_log_success "Network connectivity OK"
    else
        recon_log_warn "Cannot reach api.github.com"
    fi

    # Directories
    for d in "$RECON_OUTPUT_DIR" "$RECON_CACHE_DIR" "$RECON_LOG_DIR"; do
        [[ -d "$d" ]] && recon_log_success "Directory OK: ${d}" || { recon_log_error "Missing: ${d}"; failed=1; }
    done

    # Shodan API test
    if [[ -n "${SHODAN_API_KEY:-}" ]]; then
        if curl -sf --max-time 10 "https://api.shodan.io/api-info?key=${SHODAN_API_KEY}" >/dev/null 2>&1; then
            recon_log_success "Shodan API key valid"
        else
            recon_log_warn "Shodan API key test failed"
        fi
    fi

    if [[ "$failed" -eq 0 ]]; then
        recon_log_success "Health check passed"
    else
        recon_log_error "Health check completed with errors"
    fi
    return "$failed"
}

recon_require_tool() {
    local tool="$1"
    recon_has_tool "$tool" || {
        recon_log_error "Required tool '${tool}' not found."
        recon_install_hint "$tool"
        return 1
    }
}
