#!/usr/bin/env bash
# shellcheck shell=bash
# Web application testing: dir brute, JS recon, screenshots

dirsearch() {
    local url="$1"
    local extensions="${2:-php,html,txt,js,bak,conf}"
    local script
    script="$(recon_tool_path dirsearch/dirsearch.py)"
    if [[ -f "$script" ]]; then
        python3 "$script" -u "$url" -e "$extensions" "${@:3}"
    elif recon_has_tool feroxbuster; then
        feroxbuster -u "$url" -x "$extensions"
    elif recon_has_tool ffuf; then
        local wl="${3:-/usr/share/seclists/Discovery/Web-Content/common.txt}"
        ffuf -u "${url}/FUZZ" -w "$wl" -mc 200,204,301,302,307,401,403
    else
        recon_log_error "Install dirsearch, feroxbuster, or ffuf"
        return 1
    fi
}

gobuster_dir() {
    local url="$1"
    local wordlist="${2:-/usr/share/seclists/Discovery/Web-Content/common.txt}"
    recon_require_tool gobuster || return 1
    gobuster dir -u "$url" -w "$wordlist" \
        -s 200,204,301,302,307,401,403 \
        -x html,bak,sql,php,py,txt,conf,cgi,exe,json,xml,js \
        -e -b '' -t "${DEFAULT_THREADS:-50}" -o gobuster.out --no-error
}

wfuzz_dir() {
    local wordlist="$1"
    local url="$2"
    recon_require_args 2 "$@" || return 1
    recon_require_tool wfuzz || return 1
    wfuzz -w "$wordlist" -c --hc 404 "$url"
}

gowitness_screenshot() {
    local input="$1"
    recon_validate_file "$input" "URL list" || return 1
    recon_require_tool gowitness || return 1
    gowitness file -f "$input" -t "${DEFAULT_THREADS:-100}"
    gowitness report export -f gowitness_export
    gowitness report list > report_list
}

aquatone_screenshot() {
    local input="$1"
    local ports="${2:-80,443,8080,8443}"
    recon_require_tool aquatone || return 1
    mkdir -p screenshots && cd screenshots || return 1
    cat "../${input}" | aquatone --ports "$ports"
    cd - >/dev/null || true
}

eyewitness_screenshot() {
    local input="$1"
    local output="${2:-dump-screenshots}"
    local script
    script="$(recon_tool_path EyeWitness/Python/EyeWitness.py)"
    recon_validate_file "$input" "URL list" || return 1
    if [[ -f "$script" ]]; then
        python3 "$script" --no-prompt --timeout 20 --delay 10 --max-retries 5 \
            -f "$input" -d "$output"
    elif recon_has_tool gowitness; then
        gowitness_screenshot "$input"
    else
        recon_log_error "EyeWitness or gowitness required"
        return 1
    fi
}

secretfinder_url() {
    local url="$1"
    local script
    script="$(recon_tool_path SecretFinder/SecretFinder.py)"
    [[ -f "$script" ]] || { recon_log_error "SecretFinder not found"; return 1; }
    python3 "$script" -i "$url" -o cli
}

secretfinder_urls() {
    local file="$1"
    recon_validate_file "$file" "URL list" || return 1
    : > secretfinder-results.txt
    while IFS= read -r url; do
        [[ -z "$url" ]] && continue
        secretfinder_url "$url" | tee -a secretfinder-results.txt
    done < "$file"
}

linkfinder() {
    local input="$1"
    local script
    script="$(recon_tool_path LinkFinder/linkfinder.py)"
    [[ -f "$script" ]] || { recon_log_error "LinkFinder not found"; return 1; }
    python3 "$script" -i "$input" -o cli
}

beautify_js() {
    local file="$1"
    recon_require_tool js-beautify || return 1
    js-beautify -o beautified.txt "$file"
}

recon_js_enum() {
    local domain="$1"
    recon_validate_domain "$domain" || return 1
    gau_js "$domain"
    wayback_js "$domain"
    hakrawler_js "$domain"
    gospider_js "$domain"
    subjs_fetch "$domain"
    cat gau_jslink.txt wayback_jsfiles.txt hakrawler_jsfiles.txt gospider_jsfiles.txt subjs_jsfiles.txt 2>/dev/null | \
        sort -u > jslinks.final
    rmf gau_jslink.txt wayback_jsfiles.txt hakrawler_jsfiles.txt gospider_jsfiles.txt subjs_jsfiles.txt
    grep "$domain" jslinks.final > alive-jslinks.txt 2>/dev/null || cp jslinks.final alive-jslinks.txt
    secretfinder_urls alive-jslinks.txt
    recon_notify INFO "JS recon for ${domain} finished"
}

recon_js_enum_multi() {
    local input="$1"
    local company="${2:-target}"
    gospider_js_multi "$input"
    subjs_multi "$input"
    cat subjs_jsfiles_multi.txt gospider_jsfiles_multi.txt 2>/dev/null | sort -u > jslinks_multi.final
    cat jslinks_multi.final | httpx -silent -mc 200 | tee alive-jslinks_multi.txt
    rmf subjs_jsfiles_multi.txt gospider_jsfiles_multi.txt
    secretfinder_urls alive-jslinks_multi.txt
    recon_notify INFO "JS recon for ${company} finished"
}

retire_js() {
    local path="$1"
    local output="${2:-retire.json}"
    recon_require_tool retire || return 1
    retire --path "$path" --outputformat json --outputpath "$output"
    python3 -m json.tool "$output" 2>/dev/null || cat "$output"
}

cewl_wordlist() {
    local url="$1"
    recon_require_tool cewl || return 1
    cewl -d 2 -m 5 -w cewl.out "$url"
}

subjack_check() {
    local input="$1"
    recon_require_tool subjack || return 1
    local fp="${RECON_TOOLS_DIR}/subjack/fingerprints.json"
    subjack -w "$input" -t "${DEFAULT_THREADS:-100}" -o subjack.out -ssl -c "$fp"
}

# Legacy aliases
_dirsearch() { dirsearch "$@"; }
_gobuster() { gobuster_dir "$@"; }
_wfuzz() { wfuzz_dir "$@"; }
_gowitness() { gowitness_screenshot "$@"; }
_aquatone() { aquatone_screenshot "$@"; }
_eyewitness() { eyewitness_screenshot "$@"; }
_secretfinder_url() { secretfinder_url "$@"; }
_secretfinder_urls() { secretfinder_urls "$@"; }
_linkfinder() { linkfinder "$@"; }
_beautifiy_js() { beautify_js "$@"; }
_recon_js_enum() { recon_js_enum "$@"; }
_recon_js_enum_multi() { recon_js_enum_multi "$@"; }
_retire() { retire_js "$@"; }
_cewl() { cewl_wordlist "$@"; }
_subjack() { subjack_check "$@"; }
