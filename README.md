# Reconix

Production-ready Bash framework for penetration testing, bug bounty hunting, and security research.

**Version:** 1.0.0  
**GitHub:** [Reconix](https://github.com/your-org/Reconix)

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
git clone https://github.com/your-org/Reconix.git
cd Reconix
./setup.sh
# Edit ~/.config/reconix/config.env with your API keys
reconix health
reconix recon example.com
reconix workflow full example.com
```

## Installation

See [docs/INSTALL.md](docs/INSTALL.md) for full instructions.

```bash
./setup.sh                  # Basic install
./setup.sh --with-go-tools  # Install ProjectDiscovery tools via Go
make install
```

## Configuration

Copy and edit `~/.config/reconix/config.env`:

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
reconix health
reconix recon example.com
reconix recon-multi domains.txt
reconix httpx targets.txt
reconix nuclei alive-hosts.txt
reconix report ./workspace example.com

reconix workflow full example.com
reconix workflow bugbounty example.com

# Source in shell (legacy compatibility)
source /path/to/Reconix/reconix
recon_subdomains_no_brute example.com
```

## Project Structure

```
Reconix/
├── reconix              # Main CLI executable
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

1. Run `./setup.sh`
2. Move credentials to `~/.config/reconix/config.env`
3. Replace `source functions_pro.sh` with `source /path/to/Reconix/reconix`
4. Legacy aliases preserved (e.g. `_crtsh`, `_httpx`, `_tnotify_recon`)

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

Run `reconix health` to check your environment.

## License

MIT — see [LICENSE](LICENSE)
