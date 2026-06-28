#!/usr/bin/env bash
# shellcheck shell=bash

nuclei_update() {
    recon_require_tool nuclei || return 1
    nuclei -update-templates -update-directory "${RECON_NUCLEI_TEMPLATES}"
}
