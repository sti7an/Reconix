#!/usr/bin/env bash
# shellcheck shell=bash
# Password cracking and hash analysis

john_crack() {
    local hashfile="$1"
    recon_validate_file "$hashfile" "hash file" || return 1
    recon_require_tool john || return 1
    john --wordlist="${JOHN_WORDLIST:-/usr/share/wordlists/rockyou.txt}" "$hashfile"
    john --show "$hashfile"
}

hashcat_crack() {
    local hashfile="$1"
    local mode="$2"
    recon_require_args 2 "$@" || return 1
    recon_validate_file "$hashfile" "hash file" || return 1
    recon_require_tool hashcat || return 1
    local wordlist="${HASHCAT_WORDLIST:-/usr/share/wordlists/rockyou.txt}"
    local rules="${HASHCAT_RULES:-/usr/share/hashcat/rules/best64.rule}"
    hashcat --user -m "$mode" "$hashfile" "$wordlist" -r "$rules" --force
}

parse_cvs_hashes() {
    _parse_cvs "$@"
}

# Legacy aliases
johnnow() { john_crack "$@"; }
hashnow() { hashcat_crack "$@"; }
_parseCVS() { _parse_cvs "$@"; }
