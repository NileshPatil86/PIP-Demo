# Non-secret backend configuration. Fill these in with the outputs from the
# `bootstrap` stack, then run: terraform init -backend-config=backend.hcl
#
# Authentication to this storage account is via Azure AD (use_azuread_auth),
# using whichever identity is currently logged in (your `az login` session
# locally, or the OIDC-federated GitHub Actions identity in CI). No storage
# account keys are used or stored anywhere.

resource_group_name  = "rg-pip-demo-tfstate"
storage_account_name = "REPLACE_WITH_BOOTSTRAP_OUTPUT"
container_name       = "tfstate"
key                  = "prod/aks.terraform.tfstate"
use_azuread_auth     = true
