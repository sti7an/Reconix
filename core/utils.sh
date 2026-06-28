#!/usr/bin/env bash
# shellcheck shell=bash
# Utility functions: retry, parallel, paths, helpers

recon_retry() {
    local max="${1:-${MAX_RETRIES:-3}}"
    shift
    local attempt=1 backoff="${RETRY_BACKOFF:-2}"
    local delay=1

    while [[ "$attempt" -le "$max" ]]; do
        if "$@"; then
            return 0
        fi
        if [[ "$attempt" -lt "$max" ]]; then
            recon_log_warn "Attempt ${attempt}/${max} failed, retrying in ${delay}s..."
            sleep "$delay"
            delay=$((delay * backoff))
        fi
        attempt=$((attempt + 1))
    done
    recon_log_error "Command failed after ${max} attempts: $*"
    return 1
}

recon_run_timeout() {
    local timeout="${1:-${DEFAULT_TIMEOUT:-10}}"
    shift
    if recon_has_tool timeout; then
        timeout "$timeout" "$@"
    else
        "$@"
    fi
}

recon_parallel_run() {
    local jobs="${1:-${MAX_PARALLEL:-4}}"
    shift
    local cmd=("$@")
    local running=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue
        "${cmd[@]}" "$line" &
        running=$((running + 1))
        if [[ "$running" -ge "$jobs" ]]; then
            wait -n 2>/dev/null || wait
            running=$((running - 1))
        fi
    done
    wait
}

recon_dedupe_file() {
    local input="$1"
    local output="${2:-${input}.deduped}"
    sort -u "$input" > "$output"
    echo "$output"
}

recon_count_unique() {
    local file="$1"
    recon_validate_file "$file" "input" || return 1
    sort -u "$file" | wc -l | tr -d ' '
}

recon_today_folder() {
    date '+%Y-%m-%d'
}

recon_safe_rm() {
    local target="$1"
    [[ "${INTERACTIVE:-true}" == "true" ]] && ! recon_confirm "Delete ${target}?" && return 1
    [[ "${DRY_RUN:-false}" == "true" ]] && { recon_log_info "[DRY-RUN] rm -rf ${target}"; return 0; }
    rm -rf "$target"
}

recon_mkdir_work() {
    local dir="$1"
    mkdir -p "$dir"
    cd "$dir" || return 1
}

recon_tool_path() {
    local name="$1"
    local path="${RECONIX_TOOLS_DIR}/${name}"
    [[ -e "$path" ]] && echo "$path" || echo "$name"
}

# --- Legacy utility wrappers (migrated from functions_pro.sh) ---

xclipy() {
    recon_require_args 1 "$@" || return 1
    command -v xclip >/dev/null 2>&1 || { recon_log_error "xclip not installed"; return 1; }
    xclip -selection clipboard "$@"
}

_parse_cvs() {
    local file="$1"
    recon_validate_file "$file" "CSV file" || return 1
    cut -d "," -f 1 "$file" | sed 's/"//g' > usernames
    cut -d "," -f 2 "$file" | sed 's/"//g' > emails
    cut -d "," -f 3 "$file" | sed 's/"//g' > hashes
    paste -d ":" emails hashes > JohnFormat.lst
}

_print_success() { recon_log_success "$1"; }
_print_failure() { recon_log_failure "$1"; }

countsorted() {
    recon_require_args 1 "$@" || return 1
    recon_validate_file "$1" "input" || return 1
    sort -u "$1" | wc -l
}

rmf() {
    for f in "$@"; do
        [[ -e "$f" ]] && rm -rf "$f"
    done
}

getrootdomain() {
    local domain="$1"
    echo "$domain" | cut -d . -f 2-
}

getfqdn() {
    local domain="$1"
    echo "$domain" | grep -oP '(?<=\.).+' 2>/dev/null || echo "$domain" | rev | cut -d. -f1-2 | rev
}

grep_ips() {
    grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' "$@" | sort -u
}

_grep_ips() { cat "$@" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u; }
_grep_emails() { grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$@" | sort -u; }

encode_url() {
    echo "$1" | curl -Gso /dev/null -w '%{url_effective}' --data-urlencode @- "" | cut -c 3-
}

decode_base64() {
    echo "$1" | base64 -d 2>/dev/null || echo "$1" | base64 -D 2>/dev/null
}

disp_folder_size() {
    ls -l "$@" 2>/dev/null | awk 'BEGIN {total=0}{total+=$5}END{print total/1024/1024" MB"}'
}

search_files_parallel() {
    if [[ "$#" -lt 2 ]]; then
        recon_log_error "Usage: search_files_parallel <parent_directory> <pattern> [rg_options...]"
        return 1
    fi
    local parent_directory="$1" pattern="$2"
    shift 2
    cd "$parent_directory" || return 1
    recon_require_tool rg || return 1
    find . -type f -print0 | xargs -0 -P "${MAX_PARALLEL:-4}" rg "$pattern" "$@"
}

extract_ports() {
    local input_file="${1:-allnmap}"
    local output_file="${2:-ip_port_list.txt}"
    recon_validate_file "$input_file" "nmap output" || return 1
    grep "Discovered open port" "$input_file" | \
        awk '{print $6 ":" $4}' | \
        sed 's/\/tcp//;s/\/udp//' | \
        sort -u > "$output_file"
    recon_log_success "Saved $(wc -l < "$output_file") entries to ${output_file}"
}
