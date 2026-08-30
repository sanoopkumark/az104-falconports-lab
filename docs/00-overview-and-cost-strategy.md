# Phase 0 — Foundations: Tenant, Subscription Hygiene, Budget

Do everything in this phase before creating a single VM or storage account. It's the difference between a lab that costs $10/month and one that quietly costs $150.

## 0.1 Naming and tagging convention

Pick one convention and use it everywhere — consistency is itself an AZ-104 governance skill.

**Resource group naming:** `rg-<cluster>-<env>` → `rg-platform-prod`, `rg-ports-prod`, `rg-maritime-prod`, `rg-logistics-prod`, `rg-freezones-prod`

**Resource naming:** `<resource-type-abbr>-<cluster>-<purpose>-<###>` → `vm-ports-web-001`, `st<cluster><purpose>` (storage accounts must be globally unique, lowercase, no dashes, ≤24 chars) → e.g. `stfalconlogsdocs01`

**Mandatory tags on every resource group:**

| Tag | Example value |
|---|---|
| `Cluster` | `Ports` / `Maritime` / `Logistics` / `FreeZones` / `Platform` |
| `Environment` | `Lab` |
| `Owner` | your name |
| `CostCenter` | `AZ104-Training` |
| `AutoShutdown` | `Yes` / `No` |

## 0.2 Region

Default to **`uaenorth`** (Dubai) — it keeps latency realistic for a "UAE company" scenario. Some SKUs (certain B-series sizes, Bastion Developer SKU, newer VM Scale Set features) roll out to smaller regions later, so if a deployment fails with a SKU/quota error, check availability and fall back to `eastus` or `westeurope`:

```bash
az vm list-skus --location uaenorth --size Standard_B --output table
az vm list-skus --location uaenorth --resource-type virtualMachines --all false --output table
```

Whichever you pick, **use one region for everything** in this lab — cross-region bandwidth is a real (if small) cost you don't need.

## 0.3 Subscription-level budget and alerts (do this FIRST)

This is also literally an AZ-104 exam skill: *"Manage costs by using alerts, budgets, and Azure Advisor recommendations."*

```bash
# scripts/set-budget.sh does this for you — or run manually:
az consumption budget create \
  --budget-name "falconports-monthly-cap" \
  --amount 25 \
  --category cost \
  --time-grain monthly \
  --start-date $(date -u +%Y-%m-01) \
  --end-date 2027-12-31 \
  --notifications '{
    "Actual_50": {"enabled": true, "operator": "GreaterThan", "threshold": 50, "contactEmails": ["YOUR_EMAIL@example.com"]},
    "Actual_80": {"enabled": true, "operator": "GreaterThan", "threshold": 80, "contactEmails": ["YOUR_EMAIL@example.com"]},
    "Actual_100": {"enabled": true, "operator": "GreaterThan", "threshold": 100, "contactEmails": ["YOUR_EMAIL@example.com"]}
  }'
```

Also turn on **Microsoft Cost Management → Cost alerts** in the portal (Credit/anomaly alerts are on by default for PAYG, but confirm your email is correct) and glance at **Azure Advisor → Cost recommendations** weekly — it will flag idle VMs and over-provisioned disks, which is exactly the habit a real Azure Administrator needs.

## 0.4 Management group + subscription

```bash
az account management-group create --name "falconports-group" --display-name "FalconPorts Group"
az account management-group subscription add \
  --name "falconports-group" \
  --subscription "<your-subscription-id>"
```

With one subscription, the management group layer is mostly there so you can practice the exam skill ("Configure management groups") and attach a Policy at the MG level — in a real multi-subscription company this is where Landing Zone policy lives.

## 0.5 Resource groups

```bash
for rg in platform ports maritime logistics freezones; do
  az group create -n "rg-${rg}-prod" -l uaenorth \
    --tags Cluster="${rg}" Environment=Lab Owner="Sanoop" CostCenter=AZ104-Training
done
```

Once this phase is done, move to [`01-identity-and-governance.md`](01-identity-and-governance.md).
