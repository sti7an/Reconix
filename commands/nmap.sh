#!/usr/bin/env bash
# shellcheck shell=bash
# Network scanning with nmap

nmap_discover() {
    recon_require_tool nmap || return 1
    sudo nmap "$@" -T4 -vvv 2>/dev/null | grep -i discovered
}

nmap_port_scan() {
    local input="$1"
    local name="${2:-scan}"
    recon_validate_file "$input" "target list" || return 1
    recon_require_tool nmap || return 1
    local ports="22,80,443,445,3306,3389,8080,8443,10443,8000,8888,9090,5432,6379,27017"
    mkdir -p "port_scanning_results/${name}"
    sudo nmap -iL "$input" -Pn -n -p "$ports" -vvv \
        -oA "port_scanning_results/${name}/${name}"
}

nmap_full_scan() {
    local target="$1"
    local name="${2:-fullscan}"
    recon_require_tool nmap || return 1
    local port_list="21,22,23,25,53,80,110,111,135,139,143,443,445,993,995,1433,1521,3306,3389,5432,5900,6379,8080,8443,10443"
    mkdir -p nmap
    if [[ -f "$target" ]]; then
        nmap -sC -Pn -sV -oA "nmap/${name}" -v -A -iL "$target" --open -p "$port_list" | tee -a nmap/allnmap
    else
        nmap -sC -Pn -sV -oA "nmap/${name}" -v --script safe -A "$target" --open -p "$port_list" | tee -a nmap/allnmap
    fi
}

nmap_live_hosts() {
    local cidr="$1"
    local output="${2:-live_hosts.txt}"
    recon_require_tool nmap || return 1
    sudo nmap "$cidr" -sn | grep "Nmap scan report" | awk '{print $5}' | \
        grep -v "nmap.org\|addresses" | tee -a "$output"
}

nmap_parser() {
    local file="$1"
    local script
    script="$(recon_tool_path nmap-parser.sh)"
    if [[ -f "$script" ]]; then
        bash "$script" "$file" --summary
    else
        grep -E "Nmap scan report|open" "$file"
    fi
}

sort_ports() {
    local nmap_file="${1:-nmap/allnmap}"
    recon_validate_file "$nmap_file" "nmap output" || return 1
    local ports
    mapfile -t ports < <(grep "Discovered open port" "$nmap_file" | awk '{print $4}' | cut -d/ -f1 | sort -u)
    mkdir -p iport
    local port
    for port in "${ports[@]}"; do
        grep "Discovered open port ${port}" "$nmap_file" | awk '{print $6}' | sort -u > "iport/${port}"
    done
}

discover_network() {
    local interface="$1"
    recon_require_args 1 "$@" || return 1
    local ip mask
    mapfile -t ip < <(route -n 2>/dev/null | grep "$interface" | awk '{print $1}')
    mapfile -t mask < <(route -n 2>/dev/null | grep "$interface" | awk '{print $3}')
    local i calc range outfile
    for i in "${!mask[@]}"; do
        calc="$(ipcalc "${ip[$i]}" "${mask[$i]}" 2>/dev/null | grep Network | awk '{print $2}')"
        [[ -n "$calc" ]] && nmap_live_hosts "$calc" "$(echo "$calc" | cut -d/ -f1)_network.txt"
    done
}

check_open_ports() {
    local file="$1"
    recon_validate_file "$file" "IP list" || return 1
    nmap_port_scan "$file" "openports"
}

# Legacy aliases
_nmap() { nmap_discover "$@"; }
_port_scan() { nmap_port_scan "$@"; }
_nmap_parser() { nmap_parser "$@"; }
_nmap_IPlive() { nmap_live_hosts "$@"; }
_nmap_ScanPort() { nmap_full_scan "$@"; }
_sortport() { sort_ports "$@"; }
checkopenports() { check_open_ports "$@"; }
