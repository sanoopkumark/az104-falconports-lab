# Phase 4 — Storage (15–20% of the exam)

Storage accounts are cheap to leave running (a few cents/month for small amounts of LRS data), so this cluster can stay up between sessions if you want — just watch what you put in it.

## 4.1 Create the storage accounts

```bash
az storage account create -g rg-logistics-prod -n stfalconlogsdocs01 \
  --sku Standard_LRS --kind StorageV2 --access-tier Hot \
  --tags Cluster=Logistics Environment=Lab

az storage account create -g rg-freezones-prod -n stfalconfzarchive01 \
  --sku Standard_LRS --kind StorageV2 --access-tier Cool \
  --tags Cluster=FreeZones Environment=Lab
```

`Standard_LRS` is the cheapest redundancy option. Briefly switch one account to `Standard_GRS` to see the geo-redundancy behavior and cost difference in the pricing calculator, then switch back to LRS.

## 4.2 Storage firewall + VNet restriction

```bash
az storage account update -n stfalconlogsdocs01 -g rg-logistics-prod \
  --default-action Deny
az storage account network-rule add -g rg-logistics-prod -n stfalconlogsdocs01 \
  --vnet-name vnet-logistics --subnet snet-logistics
```

## 4.3 Blob container + lifecycle management + tiers

```bash
az storage container create --account-name stfalconlogsdocs01 -n manifests --auth-mode login

# Lifecycle rule: move blobs to Cool after 30 days, Archive after 90, delete after 365
az storage account management-policy create -g rg-logistics-prod --account-name stfalconlogsdocs01 \
  --policy @iac/parameters/lifecycle-policy.json
```

Enable **soft delete** (blobs) and **versioning**:

```bash
az storage blob service-properties delete-policy update \
  --account-name stfalconlogsdocs01 --enable true --days-retained 7
az storage account blob-service-properties update \
  -g rg-logistics-prod -n stfalconlogsdocs01 --enable-versioning true
```

## 4.4 SAS tokens + stored access policy (external partner access)

```bash
# Stored access policy first (so it can be revoked centrally later)
az storage container policy create --account-name stfalconlogsdocs01 \
  --container-name manifests -n partner-read-policy \
  --permissions r --expiry 2026-12-31

# SAS token scoped to that policy
az storage container generate-sas --account-name stfalconlogsdocs01 \
  --name manifests --policy-name partner-read-policy --auth-mode login --as-user
```

Revoking access later is one command — `az storage container policy update ... --permissions ""` — without touching every token issued against it. This "why stored access policies exist" is a common exam scenario question.

## 4.5 Azure Files with identity-based (Entra ID) access

```bash
az storage share-rm create --storage-account stfalconlogsdocs01 -n shared-docs --quota 5

az storage account update -g rg-logistics-prod -n stfalconlogsdocs01 \
  --enable-files-aadds true   # or --enable-files-aadkerb true for cloud-only Kerberos
```

Assign an RBAC role (**Storage File Data SMB Share Contributor**) to `SG-Logistics-Operators` scoped to this storage account, then mount the share from a domain-... err, Entra-joined VM.

## 4.6 Object replication (cross-account, same or different region)

```bash
az storage account create -g rg-logistics-prod -n stfalconlogsreplica01 --sku Standard_LRS --kind StorageV2
az storage account or-policy create --account-name stfalconlogsdocs01 \
  --policy '{"destinationAccount": "stfalconlogsreplica01", "rules": [{"sourceContainer":"manifests","destinationContainer":"manifests"}]}'
```

Delete the replica account once you've confirmed replication works — it's a second full storage account otherwise sitting idle.

## 4.7 Azure Storage Explorer & AzCopy

Install [Storage Explorer](https://azure.microsoft.com/features/storage-explorer/) locally and connect using your Entra ID login (no keys needed). Practice a bulk copy with AzCopy:

```bash
azcopy copy "./sample-manifests/*" "https://stfalconlogsdocs01.blob.core.windows.net/manifests" --recursive
```

Next: [`05-monitoring-and-backup.md`](05-monitoring-and-backup.md)
