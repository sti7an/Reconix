# Changelog

All notable changes to Reconix are documented in this file.

## [1.0.0] - 2026-06-29

### Branding
- Project renamed to **Reconix** (GitHub: Reconix)
- CLI renamed from `recon-tools` to `reconix`
- Config path: `~/.config/reconix/config.env`

### Security (Critical)
- **Removed ALL hardcoded credentials** from legacy `functions_pro.sh`
- Credentials loaded from user config only
- Removed client-specific VPN shortcut functions

### Architecture
- Modularized into `core/`, `commands/`, `plugins/`, `workflows/`
- Eliminated duplicate function definitions

### Features
- Structured logging, notifications, caching, retry logic
- Health check, update check, report generation
- Installation script and comprehensive CLI
