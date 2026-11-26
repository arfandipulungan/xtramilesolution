# Brownfield migration: bringing click-built resources under Terraform

The estate already exists. Terraform must take over the resources that hold data or
identity, without recreating them, and replace the ones that are unsafe to keep.

## Strategy per resource type

| Resource | Strategy | Why |
| --- | --- | --- |
| S3 buckets, RDS data, storage accounts, Key Vaults | **Import** | Data must not be recreated |
| App Service / Functions apps and plans, ALB | **Import** | Hostnames and DNS are used by clients |
| Resource groups | **Import** | Existing resources already live in them |
| Windows VM (IIS), EC2 instances | **Replace** | Rebuild from the hardened golden image (Packer + Ansible), cut traffic over (blue/green), then retire the old host. Importing an unpatched "snowflake" keeps its problems |
| Flat / over-exposed networks | **Replace** | New spoke VNet / 3-tier VPC from the modules, peered or connected; workloads move in |
| RDS in the old VPC | **Move** | Snapshot → restore into the new private data subnets (or AWS DMS for minimal downtime), then import the new instance |

## Steps (one live root per PR)

1. **Inventory** what exists:
   - Azure: Azure Resource Graph (`az graph query -q "Resources | where resourceGroup =~ 'rg-prod-custapi'"`) or `aztfexport resource-group rg-prod-custapi` for a draft.
   - AWS: AWS Config / Resource Explorer (`aws resource-explorer-2 search --query-string "legacyweb"`).
2. **Keep real names**: add `name_overrides` to the live root's `main.tf` for every imported resource whose name does not follow the convention (most Azure names cannot be changed).
3. **Add `imports.tf`** with one `import` block per resource: `to` = the address inside the module, `id` = the cloud ID. Examples: `examples/prod/azure/customer-api`, `examples/prod/aws/legacy-web`.
4. **Open a PR.** The pipeline validates the root, checks every import target with `check_imports.py`, and runs `plan`.
5. **Review the plan**: `N to import`, plus every change the module makes to the imported resources. Those changes are the remediation (public access off, TLS-only, encryption, private endpoint...). Nothing is destroyed: a `destroy`/`replace` on an imported resource blocks the merge.
6. **Apply** in dev/staging first, then prod in a change window (environment approval).
7. **Remove `imports.tf`** in a follow-up PR. The next `plan` must show no changes; from then on the daily drift check guards it.

## Safety nets

- `prevent_destroy` on stores that hold data (Key Vault, storage, secrets) in the modules.
- Import is reversible: a `removed { from = ... lifecycle { destroy = false } }` block takes a resource out of state without deleting it.
- Later refactors use `moved { from = ... to = ... }` so resources are never recreated.
