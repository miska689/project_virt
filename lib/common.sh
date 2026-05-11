#!/bin/bash
# Shared helpers for the setup scripts.

set -euo pipefail

log()  { echo ">> $*"; }
die()  { echo "Error: $*" >&2; exit 1; }

require_root() {
    [ "$EUID" -eq 0 ] || die "run as root (sudo $0)"
}
