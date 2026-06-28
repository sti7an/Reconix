#!/usr/bin/env bash
# shellcheck shell=bash
# Crawling plugins: katana, gospider, hakrawler, subjs

katana_crawl() {
    local url="$1" out="${2:-katana.out}"
    recon_require_tool katana || return 1
    echo "$url" | katana -silent -jc -kf all -o "$out"
}

hakrawler_js() {
    local domain="$1" out="${2:-hakrawler_jsfiles.txt}"
    recon_validate_domain "$domain" || return 1
    if recon_has_tool hakrawler; then
        echo "https://${domain}" | hakrawler -d 2 -scope subs | grep -E '\.js' | sort -u | tee "$out"
    else
        recon_log_warn "hakrawler not installed"
    fi
}

gospider_js() {
    local domain="$1" out="${2:-gospider_jsfiles.txt}"
    recon_validate_domain "$domain" || return 1
    recon_require_tool gospider || return 1
    gospider -s "https://${domain}" -o gospider.tmp -c 10 -d 1 --other-source --include-subs --js
    grep -rhE 'https?://[^ ]+\.js' gospider.tmp 2>/dev/null | sort -u | tee "$out"
    rmf gospider.tmp
}

gospider_js_multi() {
    local file="$1" out="${2:-gospider_jsfiles_multi.txt}"
    recon_validate_file "$file" "domain list" || return 1
    : > "$out"
    while IFS= read -r domain; do
        [[ -z "$domain" ]] && continue
        gospider_js "$domain" gospider.tmp
        cat gospider.tmp >> "$out" 2>/dev/null
        rmf gospider.tmp
    done < "$file"
    sort -u "$out" -o "$out"
}

subjs_fetch() {
    local domain="$1" out="${2:-subjs_jsfiles.txt}"
    recon_validate_domain "$domain" || return 1
    recon_require_tool subjs || return 1
    echo "https://${domain}" | subjs | sort -u | tee "$out"
}

subjs_multi() {
    local file="$1" out="${2:-subjs_jsfiles_multi.txt}"
    recon_validate_file "$file" "URL/domain list" || return 1
    : > "$out"
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        echo "$line" | subjs >> "$out" 2>/dev/null
    done < "$file"
    sort -u "$out" -o "$out"
}

_gospider() {
    local target="$1"
    recon_require_tool gospider || return 1
    gospider -s "$target" -o gospider.out -c 10 -d 1 --other-source --include-subs
}
