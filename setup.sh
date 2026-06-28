#!/usr/bin/env bash
# shellcheck shell=bash
# recon-tools installation script

set -euo pipefail

RECON_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/recon-tools"
USER_CONFIG="${USER_CONFIG_DIR}/config.env"

echo "=== recon-tools setup v1.0.0 ==="

# Directories
mkdir -p "${RECON_ROOT}"/{output,cache,logs,cache/dns,cache/crtsh}
mkdir -p "${USER_CONFIG_DIR}"
mkdir -p "${HOME}/work/results"
mkdir -p "${HOME}/tools"

# User config
if [[ ! -f "$USER_CONFIG" ]]; then
    cp "${RECON_ROOT}/config/config.env" "$USER_CONFIG"
    echo "Created config: ${USER_CONFIG}"
    echo "  >> Edit this file and add your API keys"
else
    echo "Config exists: ${USER_CONFIG}"
fi

# Resolvers
if [[ ! -f "${RECON_ROOT}/data/resolvers/resolvers.txt" ]]; then
    cat > "${RECON_ROOT}/data/resolvers/resolvers.txt" <<'EOF'
8.8.8.8
8.8.4.4
1.1.1.1
1.0.0.1
9.9.9.9
EOF
fi

# Install CLI
INSTALL_DIR="${INSTALL_PREFIX:-${HOME}/.local/bin}"
mkdir -p "$INSTALL_DIR"
ln -sf "${RECON_ROOT}/recon-tools" "${INSTALL_DIR}/recon-tools"
echo "Linked: ${INSTALL_DIR}/recon-tools"

# Shell integration
SHELL_RC=""
for rc in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
    [[ -f "$rc" ]] && SHELL_RC="$rc" && break
done

if [[ -n "$SHELL_RC" ]] && ! grep -q "recon-tools" "$SHELL_RC" 2>/dev/null; then
    cat >> "$SHELL_RC" <<EOF

# recon-tools
export PATH="${INSTALL_DIR}:\$PATH"
[[ -f "${RECON_ROOT}/recon-tools" ]] && source "${RECON_ROOT}/recon-tools" 2>/dev/null || true
EOF
    echo "Added to ${SHELL_RC}"
fi

chmod +x "${RECON_ROOT}/recon-tools" "${RECON_ROOT}/setup.sh"
chmod +x "${RECON_ROOT}"/{core,commands,plugins,workflows}/*.sh 2>/dev/null || true

# Install Go tools (optional)
install_go_tools() {
    command -v go >/dev/null 2>&1 || { echo "Go not installed, skipping Go tools"; return 0; }
    local tools=(
        "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
        "github.com/projectdiscovery/httpx/cmd/httpx@latest"
        "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
        "github.com/projectdiscovery/katana/cmd/katana@latest"
        "github.com/tomnomnom/assetfinder@latest"
        "github.com/tomnomnom/waybackurls@latest"
        "github.com/lc/gau/v2/cmd/gau@latest"
        "github.com/tomnomnom/unfurl@latest"
        "github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest"
    )
    for t in "${tools[@]}"; do
        echo "Installing ${t}..."
        go install -v "${t}" 2>/dev/null || echo "  Warning: failed ${t}"
    done
}

if [[ "${1:-}" == "--with-go-tools" ]]; then
    install_go_tools
fi

# System packages hint
echo ""
echo "Install system packages:"
echo "  Debian/Ubuntu: sudo apt install curl jq nmap masscan dnsutils whois parallel"
echo "  macOS:         brew install curl jq nmap bind parallel"
echo "  Go tools:      ./setup.sh --with-go-tools"
echo ""

# Health check
# shellcheck source=core/bootstrap.sh
source "${RECON_ROOT}/core/bootstrap.sh"
recon_bootstrap
recon_health_check || true

echo ""
echo "Setup complete!"
echo "  1. Edit ${USER_CONFIG}"
echo "  2. Run: recon-tools health"
echo "  3. Run: recon-tools recon example.com"
