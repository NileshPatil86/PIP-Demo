# PIP-Demo — Production-grade AKS on Azure via Terraform + GitHub Actions

Skill Validation Task / POC

Provisions a production-grade Azure Kubernetes Service (AKS) cluster with Terraform, using a
remote, locked, keyless (Azure AD-authenticated) state backend and a GitHub Actions pipeline
that authenticates to Azure via OIDC — no long-lived client secrets anywhere.

> **Repo layout note:** this folder (`PIP-Demo/`) is meant to be the **root of its own git
> repository**. `.github/workflows/` only triggers when it lives at the true repo root, so if
> you're nesting this inside a larger repo, move `PIP-Demo`'s contents up to the repo root (or
> push this folder as its own repo) before pushing to GitHub.

## Folder structure

```
PIP-Demo/
├── .github/workflows/       # CI/CD pipelines (plan on PR, apply on merge w/ approval gate)
│   ├── terraform-plan.yml
│   └── terraform-apply.yml
├── bootstrap/                # One-time, run locally: creates the remote state backend
│   │                          # and the GitHub OIDC app registration. Uses LOCAL state
│   │                          # (chicken-and-egg: it creates the backend, so it can't use it).
│   ├── providers.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── modules/
│   └── aks/                  # Reusable AKS module: network, identity, cluster, node pools,
│                              # ACR, Log Analytics, Key Vault
├── environments/
│   └── prod/                  # Production environment (composes the aks module)
│       ├── backend.hcl        # Non-secret remote state config template
│       ├── versions.tf        # Provider + empty `backend "azurerm" {}` block
│       ├── providers.tf
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
├── .gitignore
└── README.md
```

## Architecture decisions baked into this module

- **Cluster exposure:** public API server, locked to an allow-list via
  `api_server_authorized_ip_ranges` (no private cluster / VPN dependency required).
- **Auth:** Azure AD (Entra ID) RBAC for Kubernetes Authorization, `local_account_disabled = true`
  (no static `kubeconfig` admin credentials), Workload Identity + OIDC issuer enabled for pod-level
  federated identities.
- **Nodes:** separate system pool (`CriticalAddonsOnly` taint, autoscaling, zone-redundant) and
  user pool (autoscaling, zone-redundant), Standard load balancer, Azure CNI Overlay + Azure network
  policy.
- **Supply chain / secrets:** dedicated Premium ACR with `AcrPull` granted to an explicit
  Terraform-managed kubelet identity (not an auto-generated one); Key Vault with RBAC
  authorization, purge protection, and the AKS Secrets Store CSI provider wired to read from it.
- **Observability:** Log Analytics workspace with AKS diagnostic settings (api-server, audit,
  controller-manager, scheduler, autoscaler, guard) and Microsoft Defender for Containers.
- **State backend:** Storage account with blob versioning + soft delete, `TLS1_2` minimum,
  **`shared_access_key_enabled = false`** — access is exclusively via Azure AD identities
  (`use_azuread_auth = true`), both for your local `az login` session and for the GitHub Actions
  OIDC identity. State locking is native to the `azurerm` backend (blob lease).

## One-time setup

### 1. Prerequisites

- Terraform >= 1.9
- Azure CLI, logged in (`az login`) as a user with rights to create resource groups, storage
  accounts, and Azure AD app registrations (e.g. Owner + Application Administrator, or equivalent).
- A GitHub repository this folder will be pushed to.

### 2. Run the bootstrap stack (local, one time)

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: subscription_id, tenant_id, state_storage_account_name (must be
# globally unique), github_org, github_repo

terraform init
terraform apply
```

This creates:

- The resource group + storage account + container that will hold Terraform remote state
  (no access keys — Azure AD auth only).
- An Azure AD App Registration + Service Principal for GitHub Actions, with **federated
  identity credentials** trusting your repo's OIDC tokens for pull requests, the `main` branch,
  and the `production` GitHub Environment — **no client secret is ever created or stored**.
- Role assignments: `Contributor` (provision resources) and `Role Based Access Control
  Administrator` (create role assignments like AcrPull / Key Vault Secrets User) at subscription
  scope for the GitHub Actions identity, plus `Storage Blob Data Contributor` on the state
  storage account.

> **Security note:** subscription-scoped `Contributor` + `RBAC Administrator` is broad, chosen
> here for a self-contained demo. For real production, narrow both role assignments to the
> specific resource group(s) this workload uses, and consider an Azure ABAC condition on the
> `RBAC Administrator` assignment restricting which roles it's allowed to grant.

Note the outputs — you'll need them in the next step:

```bash
terraform output
```

Optionally, protect this state going forward by migrating it into the storage account it just
created (add a matching `backend "azurerm" {}` block to `bootstrap/providers.tf` and run
`terraform init -migrate-state`). Keep the local `bootstrap/terraform.tfstate` out of git either
way — it's already covered by `.gitignore`.

### 3. Configure GitHub

**Repository variables** (Settings → Secrets and variables → Actions → Variables) — none of
these are secrets, since auth is via OIDC:

| Variable                              | Value                                            |
|----------------------------------------|---------------------------------------------------|
| `AZURE_CLIENT_ID`                      | `github_actions_client_id` bootstrap output       |
| `AZURE_TENANT_ID`                      | `azure_tenant_id` bootstrap output                |
| `AZURE_SUBSCRIPTION_ID`                | `azure_subscription_id` bootstrap output          |
| `TFSTATE_RESOURCE_GROUP_NAME`          | `tfstate_resource_group_name` bootstrap output    |
| `TFSTATE_STORAGE_ACCOUNT_NAME`         | `tfstate_storage_account_name` bootstrap output   |
| `TFSTATE_CONTAINER_NAME`               | `tfstate_container_name` bootstrap output         |
| `AKS_AAD_ADMIN_GROUP_OBJECT_IDS`       | JSON array, e.g. `["<entra-group-object-id>"]`    |
| `AKS_API_SERVER_AUTHORIZED_IP_RANGES`  | JSON array, e.g. `["203.0.113.4/32"]`             |

**GitHub Environment** (Settings → Environments → New environment → `production`): add required
reviewers here. This is what makes `terraform-apply.yml` pause for manual approval before it
runs `terraform apply` — the OIDC federated credential for `environment:production` created in
step 2 only trusts tokens issued for jobs targeting this exact environment name.

**Branch protection on `main`**: require the `Terraform Plan (AKS prod) / Plan` check to pass
before merging, so every change to `environments/prod` or `modules/` is planned and reviewed in
the PR before it can reach `main` (and therefore the apply workflow).

### 4. First plan/apply

Open a PR touching `environments/prod/**` — `terraform-plan.yml` runs automatically and posts
the plan as a PR comment. On merge to `main`, `terraform-apply.yml` runs `plan` again and then
waits for `production` environment approval before applying.

## Local usage (optional)

```bash
cd environments/prod
cp terraform.tfvars.example terraform.tfvars   # fill in real values
cp backend.hcl backend.hcl.local 2>/dev/null || true  # or just edit backend.hcl directly
# edit backend.hcl: set storage_account_name to the bootstrap output

terraform init -backend-config=backend.hcl
terraform plan  -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

`terraform.tfvars` is git-ignored (only `terraform.tfvars.example` is committed) since it holds
environment-specific values like your Entra admin group and authorized IP ranges.

## Getting cluster credentials

```bash
az aks get-credentials --resource-group rg-pip-demo-prod --name aks-pipdemo-prod --overwrite-existing
kubectl get nodes
```
(Or use the `kube_admin_credentials_command` Terraform output.) You must be a member of one of
the Entra ID groups listed in `aad_admin_group_object_ids` — there are no local admin accounts.
