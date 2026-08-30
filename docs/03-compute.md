# Phase 3 — Compute (20–25% of the exam)

**Cost rule for this whole phase:** deploy → practice the skill → `az vm deallocate` or delete → move on. Never leave a VM or scale set running between study sessions.

## 3.1 Deploy via Bicep (not just the portal)

The exam explicitly tests reading/modifying ARM templates and Bicep. Use [`iac/main.bicep`](../iac/main.bicep):

```bash
az deployment group create \
  --resource-group rg-ports-prod \
  --template-file iac/main.bicep \
  --parameters iac/parameters/falconports.parameters.json
```

Practice: export an existing resource as a template (`az group export --name rg-ports-prod`), then convert it to Bicep (`az bicep decompile --file exported.json`) — both are named exam skills.

## 3.2 Virtual machines

```bash
az vm create -g rg-ports-prod -n vm-ports-web-001 \
  --image Ubuntu2204 --size Standard_B1s \
  --vnet-name vnet-ports --subnet snet-ports-web --nsg nsg-ports-web \
  --public-ip-address "" --admin-username azureuser --generate-ssh-keys \
  --tags Cluster=Ports Environment=Lab
```

Practice on this VM:
- **Encryption at host**: `az vm update -g rg-ports-prod -n vm-ports-web-001 --set securityProfile.encryptionAtHost=true` (requires the feature registered on the subscription first — see docs comment in the command output if it fails).
- **Resize**: `az vm resize -g rg-ports-prod -n vm-ports-web-001 --size Standard_B2s`, then resize back down.
- **Move to another resource group**: `az resource move --destination-group rg-platform-prod --ids <vm-resource-id>`, then move it back.
- **Managed disks**: add a data disk, then detach/reattach it.
- **Availability set**: create a second, cheap B1s VM in an availability set with the first, purely to see the placement/fault-domain behavior — delete both right after.

## 3.3 Virtual Machine Scale Set (Maritime cluster — "vessel tracking")

```bash
az vmss create -g rg-maritime-prod -n vmss-maritime-tracking \
  --image Ubuntu2204 --vm-sku Standard_B1s \
  --vnet-name vnet-maritime --subnet snet-maritime-vmss \
  --instance-count 1 --admin-username azureuser --generate-ssh-keys
```

Scale manually to 2, watch it happen, then scale back to 0–1 and delete when done — this alone can be one of the pricier line items if left running.

## 3.4 Containers (Logistics cluster — "manifest processor")

```bash
az acr create -g rg-logistics-prod -n acrfalconports --sku Basic
az acr build -r acrfalconports -t manifest-processor:v1 .   # from a simple sample Dockerfile

az container create -g rg-logistics-prod -n manifest-processor \
  --image acrfalconports.azurecr.io/manifest-processor:v1 \
  --registry-login-server acrfalconports.azurecr.io \
  --cpu 1 --memory 1 --restart-policy Never
```

ACI bills per second and stops billing once the container exits — ideal for a "runs for 2 minutes, produces a result" workload. Delete the ACR (`az acr delete`) once you've practiced with it; Basic tier has a small daily cost.

Also try **Azure Container Apps** for the same workload to compare the two container hosting models the exam covers:

```bash
az containerapp env create -g rg-logistics-prod -n cae-falconports --location uaenorth
az containerapp create -g rg-logistics-prod -n manifest-processor-ca \
  --environment cae-falconports \
  --image acrfalconports.azurecr.io/manifest-processor:v1 \
  --min-replicas 0 --max-replicas 1
```

`--min-replicas 0` means it scales to zero (and to $0 compute) when idle.

## 3.5 App Service — free tier customer portal

```bash
az appservice plan create -g rg-ports-prod -n plan-ports-portal --sku F1 --is-linux
az webapp create -g rg-ports-prod -n falconports-customer-portal \
  --plan plan-ports-portal --runtime "NODE:20-lts"
```

F1 (Free) covers: custom domain mapping (portal only, no TLS on F1), configuring app settings/networking, and basic deployment. To practice **deployment slots**, **custom TLS certificates**, and **backup for App Service** — all of which need at least the Standard (S1) tier — scale up for one focused session, do all three, then immediately scale back to F1 or delete:

```bash
az appservice plan update -g rg-ports-prod -n plan-ports-portal --sku S1
# ... practice slots, TLS, backup here ...
az appservice plan update -g rg-ports-prod -n plan-ports-portal --sku F1
```

S1 costs roughly $0.10/hour — a couple of focused hours is a negligible cost, left running for days is not.

Next: [`04-storage.md`](04-storage.md)
