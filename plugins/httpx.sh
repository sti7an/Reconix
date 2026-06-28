#!/usr/bin/env bash
# shellcheck shell=bash

httpx_alive() {
    httpx_probe "$@"
}
