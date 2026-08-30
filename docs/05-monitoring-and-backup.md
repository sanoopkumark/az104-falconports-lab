# Phase 5 — Monitor & Maintain Azure Resources (10–15% of the exam)

This is the smallest exam domain but the most expensive to leave running unattended — Log Analytics ingestion and Backup storage both quietly accrue cost. Budget one focused session, do the whole thing, then follow the cleanup steps at the end.

## 5.1 Log Analytics workspace + diagnostic settings

```bash
az monitor log-analytics workspace create -g rg-platform-prod -n law-falconports \
  --location uaenorth

# Route diagnostics from the Ports VM to it
az monitor diagnostic-settings create --name diag-ports-web \
  --resource <vm-ports-web-001 resource-id> \
  --workspace law-falconports \
  --logs '[{"category": "Administrative","enabled": true}]' \
  --metrics '[{"category": "AllMetrics","enabled": true}]'
```

5 GB/month ingestion is free on every Log Analytics workspace — for a lab this size you will not exceed it if you only route a handful of resources.

## 5.2 VM Insights

Enable VM Insights on `vm-ports-web-001` and `vmss-maritime-tracking` from **Azure Monitor → Virtual Machines → Insights**. Explore the auto-generated performance and map views — this is exactly what "configure and interpret monitoring of VMs, storage accounts, and networks by using Azure Monitor Insights" means on the exam.

## 5.3 Log queries (KQL)

Run a few queries against `law-falconports` in **Logs**:

```kusto
Perf
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| summarize avg(CounterValue) by bin(TimeGenerated, 5m), Computer
| render timechart
```

```kusto
AzureActivity
| where OperationNameValue has "delete"
| project TimeGenerated, Caller, ResourceGroup, OperationNameValue
```

## 5.4 Alerts + action groups

```bash
az monitor action-group create -g rg-platform-prod -n ag-falconports-admins \
  --short-name fpadmins --email admin YOUR_EMAIL@example.com

az monitor metrics alert create -g rg-ports-prod -n high-cpu-ports-web \
  --scopes <vm-ports-web-001 resource-id> \
  --condition "avg Percentage CPU > 80" \
  --action ag-falconports-admins \
  --description "Ports web VM CPU sustained above 80%"
```

Also create a **budget-based action group alert** (ties back to Phase 0) so you get one alert pipeline for both operational and cost signals — a realistic pattern for a lean IT team.

## 5.5 Network Watcher / Connection Monitor

```bash
az network watcher connection-monitor create -g rg-platform-prod \
  --location uaenorth --name cm-ports-to-maritime \
  --endpoint-source-resource-id <vm-ports-web-001 resource-id> \
  --endpoint-dest-resource-id <vmss-maritime-tracking resource-id> \
  --endpoint-dest-address 10.2.1.4 --test-config-tcp-port 443
```

## 5.6 Azure Backup (Recovery Services vault)

```bash
az backup vault create -g rg-platform-prod -n rsv-falconports --location uaenorth

az backup policy create -g rg-platform-prod --vault-name rsv-falconports \
  --name policy-daily-7day --policy iac/parameters/backup-policy.json \
  --backup-management-type AzureIaasVM

az backup protection enable-for-vm -g rg-platform-prod --vault-name rsv-falconports \
  --vm vm-ports-web-001 --policy-name policy-daily-7day
```

Keep retention short (7 days) for the lab — trigger **one on-demand backup**, then **one restore**, to prove the workflow, then disable protection and delete the recovery point before it accumulates storage cost:

```bash
az backup protection disable -g rg-platform-prod --vault-name rsv-falconports \
  --container-name "IaasVMContainer;iaasvmcontainerv2;rg-ports-prod;vm-ports-web-001" \
  --item-name "vm-ports-web-001" --delete-backup-data true --yes
```

## 5.7 Azure Site Recovery (config-only unless you want the cost)

Site Recovery is the most expensive item in the whole syllabus if left running (per-instance replication cost + destination storage). Recommended approach for a cost-limited lab:

1. Create the Recovery Services vault (can reuse `rsv-falconports`).
2. Walk through **enabling replication** for `vm-ports-web-001` to a second region in the portal, reading each screen carefully — this alone teaches the concept and the exam's "Configure Azure Site Recovery for Azure resources" skill.
3. If you do enable replication to test a **failover**, do it in a single focused session: enable → test failover → clean up test failover → **disable replication** immediately (`az backup` equivalent is portal-driven for ASR). Do not leave replication enabled between sessions.

Next: [`06-teardown-and-cost-control.md`](06-teardown-and-cost-control.md)
