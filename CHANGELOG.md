# Changelog

All notable changes to recon-tools are documented in this file.

## [1.0.0] - 2026-06-29

### Security (Critical)
- **Removed ALL hardcoded credentials** from legacy `functions_pro.sh`
- Credentials now loaded from `~/.config/recon-tools/config.env`
- Removed client-specific VPN shortcut functions

### Architecture
- Modularized into `core/`, `commands/`, `plugins/`, `workflows/`
- Eliminated duplicate function definitions

### Features
- Structured logging, notifications, caching, retry logic
- Health check, update check, report generation
- Installation script and comprehensive CLI
