#!/usr/bin/env bash
# shellcheck shell=bash
# DNS-related functions

# --- DNS configuration ---

set_dns() {
    recon_log_warn "Modifying /etc/resolv.conf requires root"
    recon_confirm "Add Google DNS (8.8.8.8) to resolv.conf?" || return 1
    echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf >/dev/null
}

resolve_domain() {
    local domain="$1"
    recon_require_args 1 "$@" || return 1
    dig +short A "$domain" 2>/dev/null
}

get_ip() {
    local domain="$1"
    recon_require_args 1 "$@" || return 1
    host "$domain" 2>/dev/null | awk '/has address/ {print $4; exit}'
}

list_ns() {
    local domain="$1"
    recon_validate_domain "$domain" || return 1
    dig "$domain" ANY +noall +answer | grep 'NS' | awk '{print $5}' | sed 's/\.$//' | tee -a "${domain}-NS-RECORDs.txt"
}

list_soa() {
    local domain="$1"
    dig "$domain" ANY +noall +answer | grep 'SOA' | tee -a "${domain}-SOA-RECORDs.txt"
}

list_txt() {
    local domain="$1"
    dig "$domain" ANY +noall +answer | grep 'TXT' | tee -a "${domain}-TXT-RECORDs.txt"
}

list_spf() {
    local domain="$1"
    dig "$domain" ANY +noall +answer | grep -i spf | tee -a "${domain}-SPF-RECORDs.txt"
}

list_mx() {
    local domain="$1"
    dig "$domain" ANY +answer | grep -i mx | tee -a "${domain}-MX-RECORDs.txt"
}

list_a() {
    local domain="$1"
    nslookup -type=A "$domain" 2>/dev/null | grep Address | grep -v 53 | awk '{print $2}' | tee -a "${domain}-A-RECORDs.txt"
}

list_aaaa() {
    local domain="$1"
    nslookup -type=AAAA "$domain" 2>/dev/null | grep Address | grep -v 53 | awk '{print $2}' | tee -a "${domain}-AAAA-RECORDs.txt"
}

check_dns_records() {
    local domain="$1"
    recon_validate_domain "$domain" || return 1
    dig "$domain" ANY +noall +answer 2>/dev/null | tee -a dig.out
    host -a "$domain" 2>/dev/null | tee -a host.out
    nslookup -type=ANY "$domain" 2>/dev/null | tee -a nslookup.out
    cat dig.out host.out nslookup.out > "${domain}-all-records"
    rmf dig.out host.out nslookup.out
}

list_dns_records() {
    local domain="$1"
    recon_validate_domain "$domain" || return 1
    mkdir -p "${domain}-DNS-RECORDS" && cd "${domain}-DNS-RECORDS" || return 1
    list_ns "$domain"
    list_soa "$domain"
    list_mx "$domain"
    list_txt "$domain"
    list_spf "$domain"
    list_a "$domain"
    list_aaaa "$domain"
    check_dns_records "$domain"
    cd - >/dev/null || true
}

check_axfr() {
    local domain="$1"
    local script
    script="$(recon_tool_path Python-AXFR-Test/axfr-test.py)"
    if [[ -f "$script" ]]; then
        python3 "$script" -d "$domain"
    else
        recon_log_warn "AXFR test script not found at ${script}"
        dig @"$(dig +short NS "$domain" | head -1 | sed 's/\.$//')" "$domain" AXFR
    fi
}

resolve_ips() {
    local file="$1"
    recon_validate_file "$file" "domain list" || return 1
    while IFS= read -r domain; do
        [[ -z "$domain" ]] && continue
        resolve_domain "$domain"
    done < "$file"
}

reverse_dns_nmap() {
    recon_require_tool nmap || return 1
    sudo nmap --dns-servers 8.8.8.8,8.8.4.4 -sL "$@"
}

cidr_using_asn() {
    local asn="$1"
    recon_require_args 1 "$@" || return 1
    whois -h whois.radb.net -- "-i origin ${asn}" | grep -Eo '([0-9.]+){4}/[0-9]+' | sort -u
}

show_cidr() {
    local cidr="$1"
    if recon_has_tool ipcalc; then
        ipcalc "$cidr"
    elif recon_has_tool sipcalc; then
        sipcalc "$cidr"
    else
        recon_log_error "Install ipcalc or sipcalc"
        return 1
    fi
}

# Legacy aliases
_set_dns() { set_dns "$@"; }
_resolve_domain() { resolve_domain "$@"; }
_getip() { get_ip "$@"; }
_list_NS() { list_ns "$@"; }
_list_SOA() { list_soa "$@"; }
_list_TXT() { list_txt "$@"; }
_list_SPF() { list_spf "$@"; }
_list_MX() { list_mx "$@"; }
_list_A() { list_a "$@"; }
_list_AAAA() { list_aaaa "$@"; }
_list_dns_records() { list_dns_records "$@"; }
_check_AXFR() { check_axfr "$@"; }
_resolve_ips() { resolve_ips "$@"; }
_reverse_dns_nmap() { reverse_dns_nmap "$@"; }
_cidr_using_asn() { cidr_using_asn "$@"; }
_showcidr() { show_cidr "$@"; }
