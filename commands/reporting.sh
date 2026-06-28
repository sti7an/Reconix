#!/usr/bin/env bash
# shellcheck shell=bash
# Report generation (HTML/Markdown)

report_generate() {
    local workspace="$1"
    local name="${2:-report}"
    recon_validate_dir "$workspace" "workspace" || return 1

    local out_dir="${RECON_OUTPUT_DIR}/${name}-$(date '+%Y%m%d-%H%M%S')"
    mkdir -p "$out_dir"

    local md="${out_dir}/report.md"
    local html="${out_dir}/report.html"

    {
        echo "# Recon Report: ${name}"
        echo ""
        echo "**Generated:** $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        echo "**Tool:** recon-tools v${RECON_TOOLS_VERSION}"
        echo ""
        echo "## Summary"
        echo ""
        [[ -f "${workspace}/final/domains.final" ]] && \
            echo "- Subdomains: $(wc -l < "${workspace}/final/domains.final")"
        [[ -f "${workspace}/final/alive-hosts.txt" ]] && \
            echo "- Live hosts: $(wc -l < "${workspace}/final/alive-hosts.txt")"
        [[ -f "${workspace}/final/nuclei-cves.out" ]] && \
            echo "- CVE findings: $(wc -l < "${workspace}/final/nuclei-cves.out")"
        [[ -f "${workspace}/final/nuclei-files.out" ]] && \
            echo "- File exposures: $(wc -l < "${workspace}/final/nuclei-files.out")"
        echo ""
        echo "## Findings"
        echo ""
        if [[ -f "${workspace}/final/nuclei-cves.out" ]]; then
            echo "### CVE Scan Results"
            echo '```'
            head -50 "${workspace}/final/nuclei-cves.out"
            echo '```'
        fi
    } > "$md"

    if command -v pandoc >/dev/null 2>&1; then
        pandoc "$md" -o "$html" --standalone
        recon_log_success "Reports: ${md}, ${html}"
    else
        recon_log_success "Report: ${md}"
    fi
    echo "$out_dir"
}

report_export_json() {
    local workspace="$1"
    local out="${2:-report.json}"
    recon_validate_dir "$workspace" "workspace" || return 1
    {
        echo "{"
        echo "  \"generated\": \"$(date -u '+%Y-%m-%dT%H:%M:%SZ')\","
        echo "  \"version\": \"${RECON_TOOLS_VERSION}\","
        echo "  \"subdomains\": $(wc -l < "${workspace}/final/domains.final" 2>/dev/null || echo 0),"
        echo "  \"live_hosts\": $(wc -l < "${workspace}/final/alive-hosts.txt" 2>/dev/null || echo 0),"
        echo "  \"cve_findings\": $(wc -l < "${workspace}/final/nuclei-cves.out" 2>/dev/null || echo 0)"
        echo "}"
    } > "$out"
    recon_log_success "JSON report: ${out}"
}
