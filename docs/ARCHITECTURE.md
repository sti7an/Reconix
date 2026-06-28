# Architecture

## Module Loading Order

```
recon-tools
  └── core/bootstrap.sh
        ├── colors.sh
        ├── config.sh      (loads defaults.env → config.env)
        ├── logger.sh
        ├── validator.sh
        ├── cache.sh
        ├── dependencies.sh
        ├── notifications.sh
        ├── utils.sh
        ├── commands/*.sh
        └── plugins/*.sh
```

## Design Principles

1. **No secrets in code** — all credentials via environment
2. **Single responsibility** — each command file covers one domain
3. **Legacy compatibility** — underscore-prefixed aliases for migration
4. **Fail gracefully** — optional tools skipped with warnings
5. **POSIX where possible** — `command -v`, portable stat/date

## Data Flow

```
domain → recon_subdomains_no_brute → plugins (subfinder, crt.sh, ...)
       → domains.final
       → recon_phase2 → massdns → httpx → nuclei
       → report_generate → markdown/html
```

## Extension

Add a plugin in `plugins/mytool.sh`:
```bash
mytool_scan() {
    recon_require_tool mytool || return 1
    mytool -d "$1"
}
```

Source is automatic via `bootstrap.sh`.
