#!/usr/bin/env bash
# shellcheck shell=bash
# Unit tests for recon-tools core functions

set -euo pipefail

RECON_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=core/bootstrap.sh
source "${RECON_ROOT}/core/bootstrap.sh"
recon_bootstrap

PASS=0
FAIL=0

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "PASS: ${desc}"
        PASS=$((PASS + 1))
    else
        echo "FAIL: ${desc} (expected '${expected}', got '${actual}')"
        FAIL=$((FAIL + 1))
    fi
}

assert_ok() {
    local desc="$1"
    shift
    if "$@"; then
        echo "PASS: ${desc}"
        PASS=$((PASS + 1))
    else
        echo "FAIL: ${desc}"
        FAIL=$((FAIL + 1))
    fi
}

assert_fail() {
    local desc="$1"
    shift
    if "$@" 2>/dev/null; then
        echo "FAIL: ${desc} (expected failure)"
        FAIL=$((FAIL + 1))
    else
        echo "PASS: ${desc}"
        PASS=$((PASS + 1))
    fi
}

echo "=== recon-tools tests ==="

# Validator tests
assert_ok "validate domain example.com" recon_validate_domain example.com
assert_fail "reject invalid domain" recon_validate_domain 'not valid!'
assert_ok "validate IP 192.168.1.1" recon_validate_ip 192.168.1.1
assert_fail "reject invalid IP" recon_validate_ip 999.999.999.999

# Utility tests
assert_eq "getrootdomain" "sub.example.com" "$(getrootdomain www.sub.example.com)"
assert_eq "count unique lines" "3" "$(printf 'a\na\nb\nc\n' | sort -u | wc -l | tr -d ' ')"

# Cache tests
recon_cache_set test key1 "value1"
assert_eq "cache get" "value1" "$(recon_cache_get test key1)"
recon_cache_clear test

# Config - no secrets in defaults
if grep -qE 'AAE|1546805674|4bc14ef862090a3426cbb6157ecf391289cdbc6d|23\.227\.206\.164' "${RECON_ROOT}/config/defaults.env" 2>/dev/null; then
    echo "FAIL: secrets found in defaults.env"
    FAIL=$((FAIL + 1))
else
    echo "PASS: no secrets in defaults.env"
    PASS=$((PASS + 1))
fi

# Scan codebase for leaked secrets
if grep -rqE '1546805674|4bc14ef862090a3426cbb6157ecf391289cdbc6d|23\.227\.206\.164|AAEVPN-USER02|Aae@123|32038511e1ca2c|28d4930e-dd8d' \
    "${RECON_ROOT}/core" "${RECON_ROOT}/commands" "${RECON_ROOT}/plugins" "${RECON_ROOT}/workflows" "${RECON_ROOT}/recon-tools" 2>/dev/null; then
    echo "FAIL: hardcoded secrets detected in codebase"
    FAIL=$((FAIL + 1))
else
    echo "PASS: no hardcoded secrets in codebase"
    PASS=$((PASS + 1))
fi

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]
