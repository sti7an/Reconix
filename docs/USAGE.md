# Usage Guide

## CLI Reference

```bash
recon-tools <command> [args]
```

| Command | Description |
|---------|-------------|
| `health` | Check dependencies and configuration |
| `config` | Show current configuration |
| `update` | Check for git updates |
| `recon <domain>` | Passive subdomain enumeration |
| `recon-multi <file>` | Multi-domain enumeration |
| `phase2 [company]` | Resolve, port scan, nuclei |
| `urls <domain>` | URL collection |
| `dns <domain>` | DNS record enumeration |
| `httpx <file>` | HTTP probing |
| `nuclei <file>` | CVE scanning |
| `report <workspace>` | Generate report |
| `workflow full <domain>` | Complete pipeline |

## Environment Variables

```bash
LOG_LEVEL=DEBUG recon-tools recon example.com
DRY_RUN=true recon-tools workflow full example.com
INTERACTIVE=false recon-tools nuclei targets.txt
```

## Common Workflows

### Bug Bounty Recon

```bash
recon-tools workflow bugbounty target.com
```

### Manual Step-by-Step

```bash
mkdir target && cd target
recon-tools recon target.com
cd target.com
recon-tools phase2 target target.com
recon-tools report .. target.com
```

### GitHub Secret Scanning

```bash
source recon-tools
github_dorks username
gitleaks_repo org repo-name
```

## Safety Features

- `DRY_RUN=true` — simulate without executing
- `INTERACTIVE=true` — confirm destructive operations
- `recon_confirm` — used internally before rm/sudo operations
