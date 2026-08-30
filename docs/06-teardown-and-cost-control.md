# Phase 6 — Teardown & Cost Control Routine

Run this at the end of **every single study session**. It takes five minutes and is the difference between a $10/month lab and a nasty surprise bill.

## End-of-session checklist

1. **Deallocate, don't just stop, every VM:**
   ```bash
   az vm deallocate -g rg-ports-prod -n vm-ports-web-001
   ```
   `az vm stop` from inside the OS often leaves the VM allocated (still billed for compute). `az vm deallocate` releases the compute allocation.

2. **Scale down or delete scale sets / container apps:**
   ```bash
   az vmss scale -g rg-maritime-prod -n vmss-maritime-tracking --new-capacity 0
   ```

3. **Delete anything billed per-second/minute that finished its purpose:** Container Instances, one-off test resources.

4. **Scale App Service plans back to F1** if you scaled up to Standard for slots/TLS/backup practice.

5. **Check Recovery Services vault** for orphaned backup data if you disabled protection.

6. **Review Cost Management → Cost analysis**, filtered to the last 24–48 hours, and confirm nothing unexpected is accruing.

## Full teardown (`scripts/cleanup.sh`)

When you're done with a phase entirely (not just a session), delete the whole resource group — this is the cleanest way to guarantee $0 for that cluster:

```bash
az group delete -n rg-maritime-prod --yes --no-wait
```

Because everything is defined in [`iac/`](../iac/), rebuilding a deleted resource group for the next session is one `az deployment group create` away.

## Monthly review

- Check **Cost Management → Cost analysis → Accumulated costs** against the $25 budget from Phase 0.
- Check **Azure Advisor → Cost** for "Right-size or shutdown underutilized resources" recommendations.
- Confirm the Entra ID P2 trial (if you activated one) hasn't silently auto-converted to a paid SKU — Microsoft will email before that happens, but check anyway.
