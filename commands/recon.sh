#!/usr/bin/env bash
# shellcheck shell=bash
# Reconnaissance functions - subdomain enumeration, URL discovery, workflows

_recon_resolvers() {
    local f="${RECON_RESOLVERS_FILE}"
    [[ -f "$f" ]] && echo "$f" || echo "/usr/share/seclists/Discovery/DNS/resolvers.txt"
}

_recon_wordlist() {
    local name="${1:-subdomains-top1million-5000.txt}"
    local paths=(
        "${RECON_WORDLISTS_DIR}/${name}"
        "/usr/share/seclists/Discovery/DNS/${name}"
        "${RECONIX_TOOLS_DIR}/wordlists/dns/${name}"
    )
    local p
    for p in "${paths[@]}"; do
        [[ -f "$p" ]] && { echo "$p"; return 0; }
    done
    recon_log_error "Wordlist not found: ${name}"
    return 1
}

# --- Passive subdomain sources ---

crtsh_subdomains() {
    local domain="$1" out="${2:-crtsh.out}"
    recon_validate_domain "$domain" || return 1
    local cached
    cached="$(recon_cache_get crtsh "$domain")" && { echo "$cached" | tee "$out"; return 0; }
    recon_run_timeout 30 curl -sf "https://crt.sh/?q=${domain}&output=json" | \
        jq -r '.[].name_value' 2>/dev/null | sed 's/\*\.//g' | sort -u | tee "$out"
    recon_cache_set crtsh "$domain" "$(cat "$out")"
}

certspotter_subdomains() {
    local domain="$1" out="${2:-certspotter.out}"
    recon_validate_domain "$domain" || return 1
    recon_run_timeout 30 curl -sf "https://certspotter.com/api/v0/certs?domain=${domain}" | \
        jq -r '.[].dns_names[]' 2>/dev/null | sed 's/"//g;s/\*\.//g' | sort -u | grep "$domain" | tee "$out"
}

crtsh_atom() {
    local domain="$1" out="${2:-crtsh_atom_subdomains.out}"
    recon_validate_domain "$domain" || return 1
    recon_run_timeout 30 curl -sf "https://crt.sh/atom?q=%25.${domain}" | \
        grep -oE "[^[:space:]]+\.${domain//./\\.}\$" | sort -u | tee "$out"
}

bufferover_subdomains() {
    local domain="$1" out="${2:-bufferover.out}"
    recon_run_timeout 15 curl -sf "https://dns.bufferover.run/dns?q=.${domain}" | \
        jq -r '.FDNS_A[]?, .RDNS_A[]?' 2>/dev/null | grep -oE "[a-zA-Z0-9.-]+\.${domain}" | sort -u | tee "$out"
}

jldc_subdomains() {
    local domain="$1" out="${2:-jldc_subdomains.out}"
    recon_run_timeout 15 curl -sf "https://jldc.me/anubis/subdomains/${domain}" | \
        grep -oE '([a-zA-Z0-9-]+\.)+'"${domain}" | sort -u | tee "$out"
}

recon_dev_subdomains() {
    local domain="$1"
    local key="${RECON_DEV_API_KEY:-}"
    [[ -n "$key" ]] || { recon_log_warn "RECON_DEV_API_KEY not set, skipping recon.dev"; return 0; }
    recon_run_timeout 15 curl -sf "https://recon.dev/api/search?key=${key}&domain=${domain}" | \
        jq -r '.[].rawDomains[]' 2>/dev/null
}

# --- DNS permutations ---

dnsgen_permutations() {
    local input="$1"
    recon_require_tool dnsgen || return 1
    recon_require_tool massdns || return 1
    local resolvers
    resolvers="$(_recon_resolvers)" || return 1
    dnsgen "$input" -f | sort -u | tee dnsgen_permutations
    massdns -r "$resolvers" -t A -o S dnsgen_permutations -w massdns.out
    awk '{print $3}' massdns.out | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u | tee -a ips.out
    awk '{print $1}' massdns.out | rev | cut -c2- | rev | sort -u | tee -a domains.lst
    rmf dnsgen_permutations massdns.out
}

altdns_permutations() {
    local input="$1"
    local words="${2:-$(recon_tool_path altdns/words.txt)}"
    recon_require_tool altdns || return 1
    altdns -i "$input" -o mutated_domains -w "$words" -r -s altdns.out 2>/dev/null
    cut -d ":" -f 1 altdns.out | sort -u | tee -a domains.lst
}

# --- Main subdomain enumeration workflow ---

recon_subdomains_no_brute() {
    local domain="$1"
    recon_validate_domain "$domain" || return 1

    local prefix
    prefix="$(echo "$domain" | cut -d . -f 1)"
    recon_mkdir_work "$domain" || return 1

    recon_log_info "Enumerating subdomains for ${domain}"

    local sources=(
        "assetfinder_subdomains ${domain}"
        "subfinder_passive ${domain}"
        "crtsh_subdomains ${domain}"
        "certspotter_subdomains ${domain}"
        "bufferover_subdomains ${domain}"
        "jldc_subdomains ${domain}"
        "gau_subdomains ${domain}"
        "amass_passive ${domain}"
        "shodan_subdomains ${domain}"
        "crtsh_atom ${domain}"
    )

    local src
    for src in "${sources[@]}"; do
        recon_log_debug "Running: ${src}"
        # shellcheck disable=SC2086
        ${src} 2>/dev/null || recon_log_warn "Source failed: ${src}"
    done

    cat ./* 2>/dev/null | grep "${prefix}\." | sort -u > domains.final
    grep -v -E "^\.${prefix}|^\*\.${prefix}" domains.final > sorted 2>/dev/null || cp domains.final sorted
    mv sorted domains.final
    rmf ./*.out "$prefix" 2>/dev/null || true
    cd - >/dev/null || true

    recon_notify INFO "Subdomain enumeration for ${domain} finished"
    recon_log_success "Results: ${domain}/domains.final ($(wc -l < "${domain}/domains.final" 2>/dev/null || echo 0) subdomains)"
}

recon_subdomains_no_brute_multi() {
    local domains_file="$1"
    local company="${2:-target}"
    recon_validate_file "$domains_file" "domains file" || return 1
    while IFS= read -r domain; do
        [[ -z "$domain" ]] && continue
        recon_subdomains_no_brute "$domain"
    done < "$domains_file"
    recon_notify INFO "Full subdomain enumeration for ${company} finished"
}

recon_subdomains_brute() {
    local domain="$1"
    local wordlist="${2:-$(_recon_wordlist)}"
    recon_validate_domain "$domain" || return 1
    shuffledns_brute "$domain" "$wordlist" 2>/dev/null || true
    recon_log_info "Brute-force enumeration complete for ${domain}"
}

recon_subdomains_permutations() {
    local input="$1"
    local wordlist="${2:-}"
    dnsgen_permutations "$input"
    [[ -n "$wordlist" ]] && altdns_permutations "$input" "$wordlist"
}

recon_phase2() {
    local company="${1:-target}"
    local notify_name="${2:-$company}"

    mkdir -p ../ips ../final 2>/dev/null || true

    cat ./*/* 2>/dev/null | sort -u > ../final/domains.final
    _grep_ips ./*/* > ../ips/ips 2>/dev/null || true

    local resolvers
    resolvers="$(_recon_resolvers)" || return 1
    recon_require_tool massdns || return 1

    massdns -r "$resolvers" -t A -o S ../final/domains.final -w massdns.out
    awk '{print $3}' massdns.out | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u >> ../ips/ips.out
    sort -u ../ips/ips ../ips/ips.out > ../ips/ips.final 2>/dev/null
    rmf massdns.out ../ips/ips ../ips/ips.out

    sort -u ../ips/ips.final ../final/domains.final > ../final/all

    while IFS= read -r entry; do
        [[ -z "$entry" ]] && continue
        resolve_domain "$entry"
    done < ../final/domains.final | tee -a ../final/resolved_domains.out

    cat ../final/resolved_domains.out >> ../final/all 2>/dev/null
    sort -u ../final/all -o ../final/all
    _grep_ips ../final/all > ../final/ips.final

    recon_log_info "Port scanning..."
    if recon_has_tool nmap; then
        sudo nmap -Pn -n -T4 --randomize-hosts -p 1-65535 -iL ../final/ips.final 2>/dev/null | \
            grep -i discovered | sed 's#/tcp##g' | awk '{print $6":"$4}' | tee -a ../final/portAnalysis.out
        sort -u ../final/portAnalysis.out ../final/all >> ../final/all.tmp
        mv ../final/all.tmp ../final/all
    fi

    httpx_probe ../final/all
    [[ -f alive-hosts.txt ]] && mv alive-hosts.txt ../final/

    if recon_has_tool nuclei && [[ -f ../final/alive-hosts.txt ]]; then
        nuclei_scan_cves ../final/alive-hosts.txt ../final/nuclei-cves.out
        nuclei_scan_files ../final/alive-hosts.txt ../final/nuclei-files.out
    fi

    mkdir -p ../final/JSRecon
    recon_js_enum_multi ../final/all "$notify_name"

    recon_notify INFO "Recon phase 2 for ${company} finished"
}

recon_urls() {
    local domain="$1"
    recon_validate_domain "$domain" || return 1
    mkdir -p urls && cd urls || return 1
    waybackurls_fetch "$domain"
    gau_fetch "$domain"
    touch urls.out
    cat waybackurls.out gau.out 2>/dev/null | sort -u --version-sort > urls.out
    rmf waybackurls.out gau.out commoncrawl.out 2>/dev/null
    cd - >/dev/null || true
}

init_hunting_workspace() {
    local name="$1"
    recon_require_args 1 "$@" || return 1
    local root="${CORP_ROOT_DIR}/${name}"
    mkdir -p "${root}"/{dump-PULSESECURE,dump-CREDS,dump-DATA,subdomains,urls,screenshots,nuclei}
    cd "${root}" || return 1
    recon_log_success "Workspace initialized: ${root}"
}

init_profile() {
    local corp="$1"
    recon_require_args 1 "$@" || return 1
    local root="${CORP_ROOT_DIR}/${corp}"
    sudo mkdir -p "${root}"/{dump-PULSESECURE,dump-CREDS,dump-DATA}
    cd "${root}" || return 1
}

go_profile() {
    local corp="$1"
    cd "${CORP_ROOT_DIR}/${corp}" || return 1
}

subdomains_enum() {
    local target="$1"
    if [[ -f "$target" ]]; then
        subfinder -dL "$target" -o dump-subfinder -all 2>/dev/null
        amass enum -df "$target" -o dump-amassSubs 2>/dev/null
        assetfinder --subs-only < "$target" | tee dump-assetfinder
    else
        recon_validate_domain "$target" || return 1
        subfinder -d "$target" -o dump-subfinder -all 2>/dev/null
        amass enum -d "$target" -o dump-amassSubs 2>/dev/null
        assetfinder "$target" --subs-only | tee dump-assetfinder
        echo "$target" | waybackurls 2>/dev/null | unfurl domains | tee dump-unfurl
        crtsh_subdomains "$target"
    fi
    cat dump-* 2>/dev/null | sort -u > dump-subdomains.txt
    recon_log_success "Combined results in dump-subdomains.txt"
}

# Legacy aliases
_recon_subdomains_no_brute() { recon_subdomains_no_brute "$@"; }
_recon_subdomains_no_brute_multi() { recon_subdomains_no_brute_multi "$@"; }
_recon_subdomains_brute() { recon_subdomains_brute "$@"; }
_recon_subdomains_permutations() { recon_subdomains_permutations "$@"; }
_recon_phase2() { recon_phase2 "$@"; }
_recon_phase2_1() { recon_phase2 "$@"; }
_urls() { recon_urls "$@"; }
_init_hunting_workspace() { init_hunting_workspace "$@"; }
_init_profile() { init_profile "$@"; }
_go_profile() { go_profile "$@"; }
_crtsh() { crtsh_subdomains "$@"; }
_certspotter() { certspotter_subdomains "$@"; }
_crtsh_atom() { crtsh_atom "$@"; }
_bufferover_subdomains() { bufferover_subdomains "$@"; }
_jldc() { jldc_subdomains "$@"; }
_dnsgen() { dnsgen_permutations "$@"; }
_altdns() { altdns_permutations "$@"; }
_subdomains_enum() { subdomains_enum "$@"; }
subdomainsRecon() { subdomains_enum "$@"; }
