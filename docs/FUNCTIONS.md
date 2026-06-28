# Function Index

Legacy names from `functions_pro.sh` map to new functions:

## Recon
- `_recon.subdomains.noBrute` → `recon_subdomains_no_brute`
- `_recon.subdomains.noBrute.multi` → `recon_subdomains_no_brute_multi`
- `_recon.phase2` → `recon_phase2`
- `_crtsh` → `crtsh_subdomains`
- `_certspotter` → `certspotter_subdomains`
- `_gau_domains` → `gau_subdomains`
- `_shodan_domains` → `shodan_subdomains`

## HTTP
- `_httpx` → `httpx_probe`
- `_check_alive_domains` → `check_alive_domains`
- `_check_robots` → `check_robots`

## DNS
- `_resolve_domain` → `resolve_domain`
- `_list_dns_records` → `list_dns_records`
- `_getip` → `get_ip`

## Cloud
- `_ipinfo` → `ipinfo_lookup`
- `_github-dorks` → `github_dorks`
- `_remoteEye` → `remote_eyewitness`

## Notifications
- `_tnotify_recon` → `recon_notify INFO`
- `_tnotify_script_hunter` → `_tnotify_script_hunter` (alias)

## Removed (Security)
- `_AAE`, `_SFFECO`, `_SSG`, `_pomaritime` — hardcoded VPN creds
- Hardcoded GitHub token in gitleaks/gitrob
- Hardcoded Telegram tokens
- Hardcoded VPS IP `23.227.206.164`

## Utilities
- `_parseCVS` → `_parse_cvs`
- `countsorted` → `countsorted`
- `rmf` → `rmf`
- `extract_ports` → `extract_ports`
