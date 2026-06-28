#!/usr/bin/env bash
# shellcheck shell=bash
# Cloud security: AWS, Azure, GCP, S3, GitHub secrets

ipinfo_lookup() {
    local ip="$1"
    recon_validate_ip "$ip" || return 1
    local url="https://ipinfo.io/${ip}/json"
    if [[ -n "${IPINFO_TOKEN:-}" ]]; then
        url="https://ipinfo.io/${ip}?token=${IPINFO_TOKEN}"
    fi
    recon_run_timeout "${DEFAULT_TIMEOUT:-10}" curl -sf "$url"
}

shodan_host() {
    local ip="$1"
    recon_validate_ip "$ip" || return 1
    if recon_has_tool shodan; then
        shodan host "$ip"
    elif [[ -n "${SHODAN_API_KEY:-}" ]]; then
        recon_run_timeout 15 curl -sf "https://api.shodan.io/shodan/host/${ip}?key=${SHODAN_API_KEY}"
    else
        recon_require_var SHODAN_API_KEY
    fi
}

shodan_domain() {
    local domain="$1"
    recon_validate_domain "$domain" || return 1
    if recon_has_tool shodan; then
        shodan domain "$domain"
    elif [[ -n "${SHODAN_API_KEY:-}" ]]; then
        recon_run_timeout 15 curl -sf "https://api.shodan.io/dns/domain/${domain}?key=${SHODAN_API_KEY}"
    else
        recon_require_var SHODAN_API_KEY
    fi
}

shodan_subdomains() {
    local domain="$1" out="${2:-shodan_domains.out}"
    if recon_has_tool shodan; then
        shodan domain "$domain" 2>/dev/null | awk -v domain="$domain" '{print $1"."domain}' | sort -u | tee "$out"
    elif [[ -n "${SHODAN_API_KEY:-}" ]]; then
        recon_run_timeout 15 curl -sf "https://api.shodan.io/dns/domain/${domain}?key=${SHODAN_API_KEY}" | \
            jq -r '.subdomains[]?' 2>/dev/null | awk -v d="$domain" '{print $0"."d}' | sort -u | tee "$out"
    else
        recon_log_warn "Shodan not configured, skipping"
        return 0
    fi
}

shodan_org() {
    local org="$1" fields="${2:-ip_str,port,hostnames}"
    recon_require_tool shodan || return 1
    shodan download "${org}-shodan-org" "org: ${org}" --limit -1
    shodan parse --fields "$fields" --separator , "${org}-shodan-org.json.gz"
    rmf "${org}-shodan-org.json.gz"
}

shodan_hostname() {
    local hostname="$1" fields="${2:-ip_str,port}"
    recon_require_tool shodan || return 1
    shodan download "${hostname}-shodan-hostname" "hostname:${hostname}" --limit -1
    shodan parse --fields "$fields" --separator , "${hostname}-shodan-hostname.json.gz"
    rmf "${hostname}-shodan-hostname.json.gz"
}

shodan_recon() {
    local query="$1"
    recon_require_tool shodan || return 1
    shodan search "$query"
}

shodan_cidr() {
    local cidr="$1"
    recon_require_tool shodan || return 1
    shodan search "net:${cidr}"
}

censys_subdomains() {
    local domain="$1"
    recon_require_vars CENSYS_API_ID CENSYS_API_SECRET || return 1
    local script
    script="$(recon_tool_path censys-subdomain-finder/censys_subdomain_finder.py)"
    if [[ -f "$script" ]]; then
        python3 "$script" "$domain" --output censys.out \
            --censys-api-id "${CENSYS_API_ID}" --censys-api-secret "${CENSYS_API_SECRET}"
    else
        recon_log_error "censys-subdomain-finder not found in ${RECON_TOOLS_DIR}"
        return 1
    fi
}

github_dorks() {
    local user="$1"
    recon_require_var GITHUB_TOKEN || return 1
    local script
    script="$(recon_tool_path github-dorks/github-dork.py)"
    local out="${RECON_OUTPUT_DIR}/${user}-github-dorks.out"
    if [[ -f "$script" ]]; then
        GH_TOKEN="${GITHUB_TOKEN}" python3 "$script" -u "$user" -o "$out" 2>/dev/null
        recon_log_success "Results: ${out}"
    elif recon_has_tool gitrob; then
        gitrob -github-access-token "${GITHUB_TOKEN}" "$user"
    else
        recon_log_error "github-dork.py or gitrob required"
        return 1
    fi
}

gitrob_scan() {
    local org="$1"
    recon_require_var GITHUB_TOKEN || return 1
    recon_require_tool gitrob || return 1
    gitrob -github-access-token "${GITHUB_TOKEN}" "$org"
}

gitleaks_repo() {
    local org="$1" repo="$2"
    recon_require_var GITHUB_TOKEN || return 1
    recon_require_tool gitleaks || return 1
    gitleaks detect --repo-url="https://github.com/${org}/${repo}" \
        --access-token="${GITHUB_TOKEN}" -o "gitleaks-result-${repo}" -v
}

gitleaks_repos() {
    local org="$1" repo_file="$2"
    recon_validate_file "$repo_file" "repo list" || return 1
    while IFS= read -r repo; do
        [[ -z "$repo" ]] && continue
        gitleaks_repo "$org" "$repo"
    done < "$repo_file"
}

git_all_secrets() {
    recon_require_var GITHUB_TOKEN || return 1
    if recon_has_tool docker; then
        sudo docker run -it abhartiya/tools_gitallsecrets "$@" -token="${GITHUB_TOKEN}"
    else
        recon_log_error "docker required for git-all-secrets"
        return 1
    fi
}

trufflehog_scan() {
    recon_require_tool docker || return 1
    sudo docker run dxa4481/trufflehog "$@"
}

s3_bucket_check() {
    local bucket="$1"
    recon_log_info "Checking S3 bucket: ${bucket}"
    local codes
    codes="$(curl -sk -o /dev/null -w '%{http_code}' --max-time "${DEFAULT_TIMEOUT:-10}" "https://${bucket}.s3.amazonaws.com")"
    echo "HTTP ${codes} for ${bucket}.s3.amazonaws.com"
    [[ "$codes" == "200" || "$codes" == "403" ]] && recon_log_warn "Bucket exists (may be public or restricted)"
}

# Remote VPS operations (credentials from env)
remote_eyewitness() {
    local corp="$1"
    recon_require_vars VPS_IP VPS_USER || return 1
    local ssh_target="${VPS_USER}@${VPS_IP}"
    local key_opt=()
    [[ -f "${VPS_SSH_KEY:-}" ]] && key_opt=(-i "${VPS_SSH_KEY}")
    ssh -n -f "${key_opt[@]}" -t "$ssh_target" \
        "bash -ic 'cd ${VPS_WORK_DIR}/${corp}/ && nohup python3 ${RECON_TOOLS_DIR}/EyeWitness/Python/EyeWitness.py --no-prompt --timeout 20 --delay 10 --max-retries 5 -f alive.txt -d dump-screenshots > /dev/null 2>&1 &'"
}

remote_init_profile() {
    local corp="$1"
    recon_require_vars VPS_IP VPS_USER || return 1
    local ssh_target="${VPS_USER}@${VPS_IP}"
    ssh -n -f -t "$ssh_target" "bash -ic 'init_profile ${corp}'" >/dev/null 2>&1
}

copy_file_from_vps() {
    local corp="$1" file="$2"
    recon_require_vars VPS_IP VPS_USER || return 1
    scp "${VPS_USER}@${VPS_IP}:${VPS_WORK_DIR}/${corp}/${file}" .
}

copy_folder_from_vps() {
    local user="$1" remote_path="$2"
    recon_require_var VPS_IP || return 1
    scp -r "${user}@${VPS_IP}:${remote_path}" .
}

send_file_to_vps() {
    local corp="$1" file="$2"
    recon_require_vars VPS_IP VPS_USER || return 1
    scp "${CORP_ROOT_DIR}/${corp}/${file}" "${VPS_USER}@${VPS_IP}:${VPS_WORK_DIR}/${corp}/${file}"
}

send_folder_to_vps() {
    local corp="$1" folder="$2"
    recon_require_vars VPS_IP VPS_USER || return 1
    scp -r "${CORP_ROOT_DIR}/${corp}/${folder}" "${VPS_USER}@${VPS_IP}:${VPS_WORK_DIR}/${corp}/${folder}"
}

connect_vps() {
    recon_require_vars VPS_IP VPS_USER || return 1
    local key_opt=()
    [[ -f "${VPS_SSH_KEY:-}" ]] && key_opt=(-i "${VPS_SSH_KEY}")
    ssh "${key_opt[@]}" "${VPS_USER}@${VPS_IP}"
}

# Legacy aliases
_ipinfo() { ipinfo_lookup "$@"; }
_shodanhost() { shodan_host "$@"; }
_shodan_domains() { shodan_subdomains "$@"; }
_shodan_org() { shodan_org "$@"; }
_shodan_hostname() { shodan_hostname "$@"; }
_shodanrecon() { shodan_recon "$@"; }
_shodanCIDR() { shodan_cidr "$@"; }
_censys() { censys_subdomains "$@"; }
_github_dorks() { github_dorks "$@"; }
_gitrob() { gitrob_scan "$@"; }
_git_all_secrets() { git_all_secrets "$@"; }
_trufflehog() { trufflehog_scan "$@"; }
_remote_eye() { remote_eyewitness "$@"; }
_remote_init_profile() { remote_init_profile "$@"; }
_copy_file_from_vps() { copy_file_from_vps "$@"; }
_copy_folder_from_vps() { copy_folder_from_vps "$@"; }
_send_file_to_vps() { send_file_to_vps "$@"; }
_send_folder_to_vps() { send_folder_to_vps "$@"; }
_connect_vps() { connect_vps "$@"; }
