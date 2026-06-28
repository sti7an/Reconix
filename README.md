# recon-tools

Production-ready Bash framework for penetration testing, bug bounty hunting, and security research.

**Version:** 1.0.0

## Features

- Modular architecture with zero hardcoded credentials
- Passive & active subdomain enumeration from 15+ sources
- HTTP probing, nuclei scanning, JS secret discovery
- Multi-channel notifications (Telegram, Slack, Discord, Mattermost)
- Workflow automation (phase1–4, bug bounty, full recon)
- Health checks, dependency management, caching, retry logic
- ShellCheck compliant, cross-platform (Linux/macOS)

## Quick Start

```bash
cd ~/Documents/labs/recon-tools
./setup.sh
# Edit ~/.config/recon-tools/config.env with your API keys
recon-tools health
recon-tools recon example.com
recon-tools workflow full example.com
```

## Installation

See [docs/INSTALL.md](docs/INSTALL.md) for full instructions including Go tool installation.

```bash
./setup.sh                  # Basic install
./setup.sh --with-go-tools  # Install ProjectDiscovery tools via Go
make install
```

## Configuration

Copy and edit `~/.config/recon-tools/config.env`:

```bash
TELEGRAM_TOKEN=""
GITHUB_TOKEN=""
SHODAN_API_KEY=""
VPS_IP=""
VPS_USER=""
DEFAULT_THREADS=50
LOG_LEVEL=INFO
```

**Never commit credentials.** Templates are in `config/` (gitignored when populated).

## Usage

```bash
# CLI commands
recon-tools health
recon-tools recon example.com
recon-tools recon-multi domains.txt
recon-tools httpx targets.txt
recon-tools nuclei alive-hosts.txt
recon-tools report ./workspace example.com

# Workflows
recon-tools workflow full example.com
recon-tools workflow bugbounty example.com
recon-tools workflow external example.com

# Source in shell (legacy compatibility)
source /path/to/recon-tools/recon-tools
recon_subdomains_no_brute example.com
```

## Project Structure

```
recon-tools/
├── recon-tools          # Main CLI
├── setup.sh             # Installer
├── core/                # Bootstrap, config, logging, cache
├── commands/            # dns, recon, http, cloud, exploits...
├── plugins/             # Tool wrappers (subfinder, amass, gau...)
├── workflows/           # Automated pipelines
├── config/              # Configuration templates
├── docs/                # Documentation
└── tests/               # Unit tests
```

## Migration from functions_pro.sh

1. Run `./setup.sh` to install recon-tools
2. Move credentials from old script to `~/.config/recon-tools/config.env`
3. Replace hardcoded paths (`~/Desktop/tools`) with `TOOLS_DIR` in config
4. Legacy aliases preserved (e.g. `_crtsh`, `_httpx`, `_tnotify_recon`)
5. **Remove** client-specific VPN functions — use `forticonnect IP PORT USER PASS` instead

See [CHANGELOG.md](CHANGELOG.md) for full list of security fixes.

## Documentation

- [Installation](docs/INSTALL.md)
- [Usage Guide](docs/USAGE.md)
- [Architecture](docs/ARCHITECTURE.md)
- [API Reference](docs/API.md)
- [Function Index](docs/FUNCTIONS.md)

## Required Tools

**Required:** curl, jq

**Recommended:** subfinder, amass, httpx, nuclei, nmap, massdns, waybackurls, gau, assetfinder, ffuf

Run `recon-tools health` to check your environment.

## License

MIT — see [LICENSE](LICENSE)
