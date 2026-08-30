#!/usr/bin/env bash
# Configures Azure's built-in VM auto-shutdown (free feature) so a forgotten
# VM still gets deallocated automatically every day.
#
# Usage: bash scripts/auto-shutdown.sh rg-ports-prod vm-ports-web-001 2300 "Asia/Dubai"

set -euo pipefail

RG="${1:?resource group required}"
VM="${2:?vm name required}"
TIME="${3:-2300}"
TZ_NAME="${4:-Asia/Dubai}"

az vm auto-shutdown -g "$RG" -n "$VM" --time "$TIME" --time-zone "$TZ_NAME"

echo "Auto-shutdown configured for ${VM} at ${TIME} (${TZ_NAME})."
echo "Note: auto-shutdown STOPS the VM's OS but Azure typically also deallocates it;"
echo "always confirm in the portal that the VM shows 'Stopped (deallocated)', not just 'Stopped'."
