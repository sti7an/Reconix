#!/usr/bin/env bash
# shellcheck shell=bash
# HTTP probing, URL checking, status code functions

httpx_probe() {
    local input="$1"
    local output="${2:-alive-hosts.txt}"
    recon_validate_file "$input" "input" || return 1
    recon_require_tool httpx || return 1
    local ports="80,81,443,445,8080,8443,8000,8888,9090,10443,7443,6443,3000,5000"
    cat "$input" | httpx -silent -threads "${DEFAULT_THREADS:-50}" -ports "$ports" | tee "$output"
}

httpx_probe_web_ports() {
    local input="$1"
    recon_validate_file "$input" "input" || return 1
    recon_require_tool httprobe || httpx_probe "$input" && return 0
    cat "$input" | httprobe -c "${DEFAULT_THREADS:-50}" \
        -p http:81 -p https:8443 -p http:8080 -p https:10443 -p http -p http:8081 | tee -a hosts
}

check_alive_domains() {
    local input="$1"
    recon_validate_file "$input" "domain list" || return 1
    if recon_has_tool httprobe; then
        cat "$input" | httprobe | tee -a alive.domains.all.lst
        cat "$input" | httprobe -s https:8443 https:10443 http:8080 http:8081 | tee -a alive-domains.non-default.lst
        sort -u alive-domains.non-default.lst -o alive-domains.non-default.lst
        sort -u alive.domains.all.lst alive-domains.non-default.lst -o alive.domains.all.lst
    else
        httpx_probe "$input" alive.domains.all.lst
    fi
}

check_alive_urls() {
    local input="$1"
    recon_validate_file "$input" "URL list" || return 1
    if recon_has_tool hakcheckurl; then
        cat "$input" | hakcheckurl | grep -v 404 | tee -a alive_urls.out
    else
        httpx_probe "$input" alive_urls.out
    fi
}

check_live_hosts() {
    local input="$1"
    httpx_probe "$input" hosts
    httpx_probe_web_ports "$input"
    sort -u hosts -o hosts
}

get_status_code() {
    local url="$1"
    curl -sk -o /dev/null -w '%{http_code}' --max-time "${DEFAULT_TIMEOUT:-10}" "$url"
}

url_probe() {
    local input="$1"
    recon_validate_file "$input" "URL list" || return 1
    recon_require_tool httpx || return 1
    cat "$input" | httpx -silent -status-code -method -content-length
}

check_robots() {
    local input="$1"
    recon_validate_file "$input" "host list" || return 1
    sed 's#$#/robots.txt#g' "$input" | httpx -threads "${DEFAULT_THREADS:-50}" -silent \
        -status-code -method -mc 200,301,302 -content-length
}

curl_url() {
    local url="$1"
    curl -sk -w 'Status:%{http_code}\t Size:%{size_download}\t %{url_effective}\n' \
        -o /dev/null --max-time "${DEFAULT_TIMEOUT:-10}" "$url"
}

curl_urls() {
    local file="$1"
    recon_validate_file "$file" "URL list" || return 1
    while IFS= read -r url; do
        [[ -z "$url" ]] && continue
        curl_url "$url"
    done < "$file"
}

curl_200() {
    local file="$1"
    curl_urls "$file" | grep 'Status:200'
}

send_urls_to_burp() {
    local file="$1"
    recon_validate_file "$file" "URL list" || return 1
    cat "$file" | parallel -j"${DEFAULT_THREADS:-50}" -q \
        curl -x http://127.0.0.1:8080 -w 'Status:%{http_code}\t Size:%{size_download}\t %{url_effective}\n' \
        -o /dev/null -sk
}

send_url_to_burp() {
    echo "$1" | parallel -j1 -q \
        curl -x http://127.0.0.1:8080 -w 'Status:%{http_code}\t Size:%{size_download}\t %{url_effective}\n' \
        -o /dev/null -sk
}

# Legacy aliases
_httpx() { httpx_probe "$@"; }
_httprobe() { httpx_probe_web_ports "$@"; }
_httprobe_web_ports() { httpx_probe_web_ports "$@"; }
_check_alive_domains() { check_alive_domains "$@"; }
_check_alive_urls() { check_alive_urls "$@"; }
_check_live_hosts() { check_live_hosts "$@"; }
_get_status_code() { get_status_code "$@"; }
_URL_probe() { url_probe "$@"; }
_check_robots() { check_robots "$@"; }
_curl_url() { curl_url "$@"; }
_curl_urls() { curl_urls "$@"; }
_curl_200() { curl_200 "$@"; }
_send_urls_to_burp() { send_urls_to_burp "$@"; }
_send_url_to_burp() { send_url_to_burp "$@"; }
