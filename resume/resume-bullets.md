# Resume & LinkedIn material

Only include lines below for work you actually completed and can explain in an interview — an interviewer who asks "walk me through how the VNet peering works" should get a confident answer, not a repeated README line.

## One-line project summary

> Designed and deployed a multi-cluster Azure landing zone for a simulated UAE ports & logistics conglomerate, covering identity/governance, hub-spoke networking, compute, storage, and monitoring — built entirely as infrastructure-as-code and run on a self-funded, cost-capped subscription.

## Project description (for a resume "Projects" section or LinkedIn "Featured")

> **FalconPorts Group Azure Lab** — A self-directed cloud infrastructure project built while studying for the Microsoft AZ-104 (Azure Administrator Associate) certification. Modeled a fictional multi-business-unit company (ports, maritime, logistics, free zones, digital) as a realistic Azure landing zone: Microsoft Entra ID identity and RBAC design, Azure Policy governance, a hub-spoke virtual network with NSGs and Azure Bastion, VM/VM Scale Set/App Service/Container compute, tiered storage with lifecycle management, and centralized monitoring with Log Analytics and Azure Backup. Deployed with Bicep IaC and operated under an active cost-management budget with automated teardown scripts. [GitHub link]

## Resume bullet points (pick 3–5)

- Architected a 5-resource-group, hub-spoke Azure network topology with VNet peering, NSGs, application security groups, and Azure Bastion (Developer SKU) for zero-public-IP VM access.
- Designed an Entra ID RBAC model with custom role definitions and scoped role assignments across management group, subscription, and resource group boundaries; validated with effective-access reviews.
- Implemented Azure Policy for location restriction and mandatory tagging, plus resource locks, across a multi-cluster subscription.
- Built repeatable infrastructure using modular Bicep templates (network, compute, storage) deployed via Azure CLI, including converting existing deployments between ARM JSON and Bicep.
- Configured tiered Blob and Azure Files storage with SAS/stored access policies, lifecycle management, soft delete, versioning, and cross-account object replication.
- Deployed and compared three Azure compute hosting models (VM Scale Sets, Azure Container Instances, Azure Container Apps) for a simulated logistics workload.
- Set up centralized observability with Log Analytics, KQL queries, Azure Monitor alerts/action groups, and Azure Backup with tested restore operations.
- Operated the environment under an active Azure Cost Management budget with tiered spend alerts and automated shutdown/teardown scripts, keeping a full 5-domain lab running for under $15/month.

## Suggested repo `About` / topics (GitHub)

**Description:** Hands-on Azure landing zone lab for AZ-104 exam prep — identity, governance, networking, compute, storage, and monitoring, built as IaC on a cost-capped subscription.

**Topics:** `azure` `az-104` `azure-administrator` `bicep` `infrastructure-as-code` `azure-networking` `azure-entra-id` `cloud-cost-optimization` `portfolio-project`
