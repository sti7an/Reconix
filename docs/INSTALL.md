# Installation Guide

## Prerequisites

- Bash 4.0+
- curl, jq (required)
- Go 1.21+ (optional, for ProjectDiscovery tools)

## Install

```bash
git clone https://github.com/your-org/Reconix.git
cd Reconix
chmod +x setup.sh reconix
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
mkdir -p ~/.config/reconix
cp config/config.env ~/.config/reconix/config.env
chmod 600 ~/.config/reconix/config.env
```

Edit and set:
- `GITHUB_TOKEN` — GitHub API access
- `SHODAN_API_KEY` — Shodan CLI/API
- `TELEGRAM_TOKEN` + `TELEGRAM_CHAT_ID_RECON` — Notifications
- `VPS_IP` + `VPS_USER` — Remote scanning (optional)
- `TOOLS_DIR` — Path to external tools (default: `~/tools`)

## Verify

```bash
reconix health
make test
make shellcheck
```

## Migration from functions_pro.sh / recon-tools

| Old | New |
|-----|-----|
| `recon-tools` command | `reconix` |
| `~/.config/recon-tools/` | `~/.config/reconix/` |
| Hardcoded Telegram token | `TELEGRAM_TOKEN` in config.env |
| `_recon.subdomains.noBrute` | `recon_subdomains_no_brute` |

Add to shell RC:
```bash
source /path/to/Reconix/reconix
```

## Troubleshooting

- **Command not found:** Ensure `~/.local/bin` is in PATH
- **API errors:** Run `reconix config` to verify keys are set
- **Missing tools:** Run `reconix health` for install hints
