# Phase 2 — Virtual Networking (15–20% of the exam)

## 2.1 Hub-spoke VNets

| VNet | Address space | Purpose |
|---|---|---|
| `vnet-hub` | `10.0.0.0/16` | Bastion, shared NVA/firewall VM, DNS resolver |
| `vnet-ports` | `10.1.0.0/16` | Ports cluster workloads |
| `vnet-maritime` | `10.2.0.0/16` | Maritime cluster workloads |
| `vnet-logistics` | `10.3.0.0/16` | Logistics cluster workloads |

```bash
az network vnet create -g rg-platform-prod -n vnet-hub --address-prefix 10.0.0.0/16 \
  --subnet-name AzureBastionSubnet --subnet-prefix 10.0.0.0/26

az network vnet create -g rg-ports-prod -n vnet-ports --address-prefix 10.1.0.0/16 \
  --subnet-name snet-ports-web --subnet-prefix 10.1.1.0/24
az network vnet subnet create -g rg-ports-prod --vnet-name vnet-ports \
  -n snet-ports-app --address-prefix 10.1.2.0/24

az network vnet create -g rg-maritime-prod -n vnet-maritime --address-prefix 10.2.0.0/16 \
  --subnet-name snet-maritime-vmss --subnet-prefix 10.2.1.0/24

az network vnet create -g rg-logistics-prod -n vnet-logistics --address-prefix 10.3.0.0/16 \
  --subnet-name snet-logistics --subnet-prefix 10.3.1.0/24
```

## 2.2 VNet peering (hub ↔ each spoke)

```bash
az network vnet peering create -g rg-platform-prod -n hub-to-ports \
  --vnet-name vnet-hub --remote-vnet vnet-ports --allow-vnet-access true
az network vnet peering create -g rg-ports-prod -n ports-to-hub \
  --vnet-name vnet-ports --remote-vnet vnet-hub --allow-vnet-access true
# Repeat the pair for maritime and logistics
```

## 2.3 NSGs and Application Security Groups

```bash
az network nsg create -g rg-ports-prod -n nsg-ports-web
az network asg create -g rg-ports-prod -n asg-ports-webtier

az network nsg rule create -g rg-ports-prod --nsg-name nsg-ports-web -n Allow-HTTPS-Inbound \
  --priority 100 --direction Inbound --access Allow --protocol Tcp \
  --destination-port-ranges 443 --destination-asgs asg-ports-webtier

az network nsg rule create -g rg-ports-prod --nsg-name nsg-ports-web -n Deny-All-Inbound \
  --priority 4096 --direction Inbound --access Deny --protocol '*' --destination-port-ranges '*'

az network vnet subnet update -g rg-ports-prod --vnet-name vnet-ports \
  -n snet-ports-web --network-security-group nsg-ports-web
```

**Evaluate effective security rules** (an actual exam skill): Portal → VM's NIC → **Networking → Effective security rules**.

## 2.4 Azure Bastion — Developer SKU (free)

```bash
az network bastion create -g rg-platform-prod -n bastion-falconports \
  --vnet-name vnet-hub --sku Developer
```

The Developer SKU has no hourly cost and doesn't need a dedicated `/26` subnet the same way Standard does — this is the cost-safe way to practice secure VM access without exposing public IPs or paying for Standard/Premium Bastion (~$140+/month).

## 2.5 Private endpoints and service endpoints

```bash
# Service endpoint: logistics storage account reachable only from vnet-logistics
az network vnet subnet update -g rg-logistics-prod --vnet-name vnet-logistics \
  -n snet-logistics --service-endpoints Microsoft.Storage

# Private endpoint: platform Key Vault reachable only via private IP in the hub
az network private-endpoint create -g rg-platform-prod -n pe-kv-falconports \
  --vnet-name vnet-hub --subnet AzureBastionSubnet \
  --private-connection-resource-id "<keyvault-resource-id>" \
  --group-id vault --connection-name pe-kv-connection
```

(In practice give private endpoints their own subnet rather than reusing `AzureBastionSubnet` — shown simplified here; see `iac/modules/network.bicep` for the corrected version.)

## 2.6 Azure DNS

```bash
az network private-dns zone create -g rg-platform-prod -n falconports.internal
az network private-dns link vnet create -g rg-platform-prod -n hub-link \
  --zone-name falconports.internal --virtual-network vnet-hub --registration-enabled true
```

## 2.7 Load balancer

```bash
az network public-ip create -g rg-ports-prod -n pip-ports-lb --sku Standard
az network lb create -g rg-ports-prod -n lb-ports-web --sku Standard \
  --public-ip-address pip-ports-lb --frontend-ip-name feConfig --backend-pool-name bePool

az network lb probe create -g rg-ports-prod --lb-name lb-ports-web -n httpProbe \
  --protocol Tcp --port 80
az network lb rule create -g rg-ports-prod --lb-name lb-ports-web -n httpRule \
  --protocol Tcp --frontend-port 80 --backend-port 80 \
  --frontend-ip-name feConfig --backend-pool-name bePool --probe-name httpProbe
```

Also build one **internal** load balancer in front of the maritime VM scale set to practice the difference.

## 2.8 Troubleshooting

Use **Network Watcher → Connection Monitor**, **IP flow verify**, and **Next hop** between two spoke VMs to confirm peering and NSGs behave as expected before moving on.

Next: [`03-compute.md`](03-compute.md)
