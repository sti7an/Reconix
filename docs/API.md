# API Reference

## Core

| Function | Description |
|----------|-------------|
| `recon_load_config` | Load all configuration files |
| `recon_require_var NAME` | Fail if env var unset |
| `recon_log_info/warn/error` | Structured logging |
| `recon_notify LEVEL MSG` | Multi-channel notification |
| `recon_retry N cmd...` | Retry with backoff |
| `recon_cache_get/set` | TTL-based caching |
| `recon_health_check` | Full environment check |
| `recon_validate_domain/ip/file` | Input validation |

## Recon

| Function | Args | Description |
|----------|------|-------------|
| `recon_subdomains_no_brute` | domain | Passive subdomain enum |
| `recon_subdomains_no_brute_multi` | file [company] | Multi-domain enum |
| `recon_phase2` | company [notify] | Phase 2 pipeline |
| `recon_urls` | domain | URL discovery |
| `crtsh_subdomains` | domain [out] | crt.sh enumeration |
| `subdomains_enum` | domain\|file | Combined enum |

## HTTP / Web

| Function | Args | Description |
|----------|------|-------------|
| `httpx_probe` | file [out] | Probe live HTTP |
| `check_alive_domains` | file | Domain liveness |
| `dirsearch` | url [ext] | Directory brute |
| `recon_js_enum` | domain | JS file analysis |

## Cloud / OSINT

| Function | Args | Description |
|----------|------|-------------|
| `shodan_subdomains` | domain | Shodan DNS |
| `github_dorks` | user | GitHub dorking |
| `ipinfo_lookup` | ip | IP geolocation |
| `connect_vps` | | SSH to configured VPS |

## Exploits (Safe Detection)

| Function | Args | Description |
|----------|------|-------------|
| `check_pulse_connect` | ip | CVE-2019-11510 check |
| `check_cve_2020_6287` | ip port | SAP CVE check |
| `forticonnect` | ip port user pass | FortiGate VPN |

## Reporting

| Function | Args | Description |
|----------|------|-------------|
| `report_generate` | workspace [name] | MD/HTML report |
| `report_export_json` | workspace [out] | JSON summary |
