#!/usr/bin/env bash
# shellcheck shell=bash
# Nuclei and Jaeles vulnerability scanning

nuclei_scan() {
    local input="$1"
    local output="${2:-nuclei.out}"
    recon_validate_file "$input" "target list" || return 1
    recon_require_tool nuclei || return 1
    local templates="${RECON_NUCLEI_TEMPLATES}"
    nuclei -l "$input" -t "$templates" \
        -H "${BUG_BOUNTY_HEADER}" \
        -o "$output" \
        -retries "${MAX_RETRIES:-3}" \
        -timeout "${DEFAULT_TIMEOUT:-10}"
}

nuclei_scan_cves() {
    local input="$1"
    local output="${2:-nuclei-cves.out}"
    recon_validate_file "$input" "target list" || return 1
    recon_require_tool nuclei || return 1
    local templates="${RECON_NUCLEI_TEMPLATES}"
    nuclei -update-templates -update-directory "$templates" -silent 2>/dev/null || true
    nuclei -l "$input" -t "${templates}/cves" \
        -o "$output" \
        -retries "${MAX_RETRIES:-3}" \
        -timeout "${DEFAULT_TIMEOUT:-10}" \
        -silent \
        -H "${BUG_BOUNTY_HEADER}"
}

nuclei_scan_files() {
    local input="$1"
    local output="${2:-nuclei-files.out}"
    recon_validate_file "$input" "target list" || return 1
    recon_require_tool nuclei || return 1
    local templates="${RECON_NUCLEI_TEMPLATES}"
    nuclei -l "$input" -t "${templates}/files" \
        -o "$output" \
        -retries "${MAX_RETRIES:-3}" \
        -timeout "${DEFAULT_TIMEOUT:-10}" \
        -silent \
        -H "${BUG_BOUNTY_HEADER}"
}

nuclei_scan_all() {
    local input="$1"
    local output="${2:-nuclei-all.out}"
    recon_validate_file "$input" "target list" || return 1
    recon_require_tool nuclei || return 1
    local templates="${RECON_NUCLEI_TEMPLATES}"
    nuclei -l "$input" -t "$templates" \
        -exclude files -exclude cves \
        -o "$output" \
        -retries "${MAX_RETRIES:-3}" \
        -timeout "${DEFAULT_TIMEOUT:-10}" \
        -silent \
        -H "${BUG_BOUNTY_HEADER}"
}

jaeles_scan() {
    local url="$1"
    recon_require_tool jaeles || return 1
    local sigdir="${RECONIX_TOOLS_DIR}/jaeles-signatures"
    jaeles -c 300 scan -s "$sigdir" -u "$url"
}

jaeles_cves() {
    local input="$1"
    recon_validate_file "$input" "target list" || return 1
    recon_require_tool jaeles || return 1
    local sigdir="${RECONIX_TOOLS_DIR}/jaeles-signatures"
    if [[ ! -d "$sigdir" ]]; then
        git clone --depth=1 https://github.com/jaeles-project/jaeles-signatures "$sigdir"
        jaeles config -a reload --signDir "$sigdir"
    fi
    cat "$input" | jaeles scan -c "${DEFAULT_THREADS:-100}" -s "${sigdir}/cves/" -o jaeles_cves.out -q
}

# Legacy aliases
_nuclei() { nuclei_scan "$@"; }
_nuclei_cves() { nuclei_scan_cves "$@"; }
_jaeles() { jaeles_scan "$@"; }
_jaeles_cves() { jaeles_cves "$@"; }
