# Installation Guide

## Prerequisites

- Bash 4.0+
- curl, jq (required)
- Go 1.21+ (optional, for ProjectDiscovery tools)

## Install

```bash
git clone <your-repo-url> ~/Documents/labs/recon-tools
cd ~/Documents/labs/recon-tools
chmod +x setup.sh recon-tools
./setup.sh
```

### With Go Tools

```bash
./setup.sh --with-go-tools
export PATH="${HOME}/go/bin:${PATH}"
```

### System Packages

**Debian/Ubuntu:**
```bash
sudo apt update
sudo apt install curl jq nmap dnsutils whois parallel git shellcheck
```

**macOS:**
```bash
brew install curl jq nmap bind parallel git shellcheck go
```

## Configuration

```bash
mkdir -p ~/.config/recon-tools
cp config/config.env ~/.config/recon-tools/config.env
chmod 600 ~/.config/recon-tools/config.env
```

Edit and set:
- `GITHUB_TOKEN` — GitHub API access
- `SHODAN_API_KEY` — Shodan CLI/API
- `TELEGRAM_TOKEN` + `TELEGRAM_CHAT_ID_RECON` — Notifications
- `VPS_IP` + `VPS_USER` — Remote scanning (optional)
- `TOOLS_DIR` — Path to external tools (default: `~/tools`)

## Verify

```bash
recon-tools health
make test
make shellcheck
```

## Migration from functions_pro.sh

| Old | New |
|-----|-----|
| Hardcoded Telegram token | `TELEGRAM_TOKEN` in config.env |
| `H@23.227.206.164` | `VPS_USER@VPS_IP` from config |
| `~/Desktop/tools` | `TOOLS_DIR` in config |
| `_recon.subdomains.noBrute` | `recon_subdomains_no_brute` |
| `_AAE`, `_SFFECO` VPN shortcuts | **Removed** — use `forticonnect IP PORT USER PASS` |

Remove the old script from your shell RC and add:
```bash
source ~/Documents/labs/recon-tools/recon-tools
```

## Troubleshooting

- **Command not found:** Ensure `~/.local/bin` is in PATH
- **API errors:** Run `recon-tools config` to verify keys are set
- **Missing tools:** Run `recon-tools health` for install hints
