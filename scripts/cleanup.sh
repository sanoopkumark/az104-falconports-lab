#!/usr/bin/env bash
# End-of-session teardown: deallocates every VM and scales down every VMSS
# across all FalconPorts resource groups. Does NOT delete resource groups —
# for a full teardown of a cluster, use `az group delete -n <rg> --yes --no-wait` directly.
#
# Usage: bash scripts/cleanup.sh

set -euo pipefail

RESOURCE_GROUPS=(rg-platform-prod rg-ports-prod rg-maritime-prod rg-logistics-prod rg-freezones-prod)

for rg in "${RESOURCE_GROUPS[@]}"; do
  if ! az group show -n "$rg" >/dev/null 2>&1; then
    continue
  fi

  echo "== ${rg} =="

  vm_names=$(az vm list -g "$rg" --query "[].name" -o tsv || true)
  for vm in $vm_names; do
    echo "  Deallocating VM: ${vm}"
    az vm deallocate -g "$rg" -n "$vm" --no-wait
  done

  vmss_names=$(az vmss list -g "$rg" --query "[].name" -o tsv || true)
  for vmss in $vmss_names; do
    echo "  Scaling VMSS to 0: ${vmss}"
    az vmss scale -g "$rg" -n "$vmss" --new-capacity 0 --no-wait
  done

  aci_names=$(az container list -g "$rg" --query "[].name" -o tsv || true)
  for aci in $aci_names; do
    echo "  Deleting Container Instance: ${aci}"
    az container delete -g "$rg" -n "$aci" --yes --no-wait
  done
done

echo ""
echo "Cleanup commands issued (running with --no-wait, check the portal in a minute)."
echo "Now check Cost Management -> Cost analysis for the last 24-48 hours."
