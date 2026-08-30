# Phase 1 — Identities & Governance (20–25% of the exam)

## 1.0 Custom domain — replace `.onmicrosoft.com` with your own

Signing up for Azure automatically created a Microsoft Entra ID tenant for you, and made your account its **Global Administrator** — the highest privilege there is. Adding a custom domain does **not** require a Microsoft 365 subscription or any separate "Microsoft admin" account; it's a free Entra ID feature, and you already have the rights to do it. If you want to double check, go to **Entra admin center → Identity → Roles and administrators → Global Administrator** and confirm your account is listed as a member.

**Add and verify the domain:**

1. Go to [entra.microsoft.com](https://entra.microsoft.com) → **Identity → Settings → Domain names → Add custom domain**.
2. Enter `falconportsgroup.online` → **Add domain**.
3. Entra shows you a **TXT record** to create (something like host `@`, value `MS=ms12345678`, TTL `3600`). Log in to wherever you bought `falconportsgroup.online` (the registrar's DNS management page) and add exactly that record.
4. DNS can take a few minutes to a few hours to propagate. Back in Entra, click **Verify**.

**What to do once it's verified:**

- You do **not** need to (and shouldn't) delete or replace the original `<tenant>.onmicrosoft.com` domain — Entra always keeps at least one `.onmicrosoft.com` domain as a non-removable fallback, and it's fine to leave both.
- Optional: **Domain names → falconportsgroup.online → Make primary** if you want any *new* users you create from now on to default to `@falconportsgroup.online`. This needs Global Administrator (which you have).
- Update your **existing** lab users' sign-in names to the new domain:
  ```bash
  az ad user update --id ports.lead@<yourtenant>.onmicrosoft.com \
    --user-principal-name ports.lead@falconportsgroup.online
  # Repeat for maritime.lead, logistics.lead, freezones.lead, digital.lead, and yourself
  ```

From here on, every command in this repo that shows `@<yourtenant>.onmicrosoft.com` can use `@falconportsgroup.online` instead.

## 1.1 Users and groups (Microsoft Entra ID)

Create one user per cluster lead, plus yourself as Global Admin. All free — Entra ID user objects don't cost anything.

```bash
az ad user create --display-name "Ports Cluster Lead" \
  --password "ChangeMe!2026" --force-change-password-next-sign-in true \
  --user-principal-name ports.lead@<yourtenant>.onmicrosoft.com

# Repeat for: maritime.lead, logistics.lead, freezones.lead, digital.lead
```

Create **assigned** security groups per cluster (dynamic groups need Entra ID P1, see 1.2):

```bash
az ad group create --display-name "SG-Ports-Operators" --mail-nickname "sg-ports-operators"
az ad group create --display-name "SG-Maritime-Operators" --mail-nickname "sg-maritime-operators"
az ad group create --display-name "SG-Logistics-Operators" --mail-nickname "sg-logistics-operators"
az ad group create --display-name "SG-FreeZones-Operators" --mail-nickname "sg-freezones-operators"
az ad group create --display-name "SG-Platform-Admins" --mail-nickname "sg-platform-admins"

az ad group member add --group "SG-Ports-Operators" --member-id <ports.lead objectId>
```

Practice: manage user/group properties (department, job title, manager), disable a user, and configure **Self-Service Password Reset (SSPR)** under Entra ID → Password reset — free on all tiers for cloud-only accounts.

## 1.2 Entra ID Premium free trial (for Conditional Access, PIM, dynamic groups)

Separate from your Azure subscription credit, Entra ID has its own **30-day P2 free trial** you can activate any time from **Entra admin center → Licenses → Try/Buy → Free trial**. Use it to practice, then let it expire — it does not touch your Azure subscription budget:

- Conditional Access policy (e.g., require MFA for anyone accessing the FalconPorts subscription from outside UAE)
- One **dynamic group** (e.g., all users with `department = Ports`)
- **Privileged Identity Management (PIM)** — make yourself eligible (not permanent) for Owner on `rg-platform-prod`, then activate it just-in-time

## 1.3 External users (B2B guest)

Simulate a logistics partner needing limited access:

```bash
az ad user invite --invited-user-email-address partner@example.com \
  --invited-user-display-name "Noatum Logistics Partner" \
  --send-invitation-message true
```

Add the guest to `SG-Logistics-Operators` scoped to only `rg-logistics-prod`, not the whole subscription.

## 1.4 RBAC — built-in roles at different scopes

This is the single most-tested concept in this domain: **role assignment scope + how effective permissions combine.**

```bash
# Reader at the whole subscription
az role assignment create --assignee <SG-Platform-Admins objectId> \
  --role "Reader" --scope "/subscriptions/<sub-id>"

# Contributor scoped to just one resource group
az role assignment create --assignee <SG-Ports-Operators objectId> \
  --role "Contributor" --scope "/subscriptions/<sub-id>/resourceGroups/rg-ports-prod"

# Interpret effective access: a Ports operator inherits Reader (from sub scope)
# PLUS Contributor (from RG scope) = Contributor on rg-ports-prod, Reader everywhere else.
```

Check it: **Portal → rg-ports-prod → Access control (IAM) → Check access**, and separately **My permissions**, to see how Azure resolves inherited + direct assignments.

## 1.5 Custom RBAC role

```json
// iac/parameters/custom-role-ports-operator.json
{
  "Name": "Ports Operator",
  "IsCustom": true,
  "Description": "Can manage VMs and read storage in Ports cluster, cannot delete resource groups or manage RBAC.",
  "Actions": [
    "Microsoft.Compute/virtualMachines/*",
    "Microsoft.Storage/storageAccounts/read",
    "Microsoft.Network/*/read"
  ],
  "NotActions": [
    "Microsoft.Authorization/*/Delete",
    "Microsoft.Authorization/*/Write"
  ],
  "AssignableScopes": ["/subscriptions/<sub-id>/resourceGroups/rg-ports-prod"]
}
```

```bash
az role definition create --role-definition iac/parameters/custom-role-ports-operator.json
```

## 1.6 Azure Policy

```bash
# Restrict to one region
az policy assignment create --name "allowed-locations" \
  --scope "/providers/Microsoft.Management/managementGroups/falconports-group" \
  --policy "e56962a6-4747-49cd-b67b-bf8b01975c4c" \
  --params '{ "listOfAllowedLocations": {"value": ["uaenorth"]} }'

# Require the Cluster tag on new resource groups
az policy assignment create --name "require-cluster-tag" \
  --scope "/subscriptions/<sub-id>" \
  --policy "96670d01-0a4d-4649-9c89-2d3abc0a5025" \
  --params '{ "tagName": {"value": "Cluster"} }'
```

Review **Policy → Compliance** after a day — this is exactly what an Azure Administrator checks in a real job.

## 1.7 Resource locks

```bash
az lock create --name "DoNotDelete-Platform" \
  --resource-group rg-platform-prod --lock-type CanNotDelete
```

## 1.8 Cost management (revisit)

Confirm the budget from Phase 0 is active, and add a resource-group-level budget on `rg-ports-prod` alone to practice scoped budgets, not just subscription-wide ones.

Next: [`02-networking.md`](02-networking.md)
