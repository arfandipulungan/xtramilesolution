# One naming + tagging standard for every cloud. The CI/CD pipeline (Task 1)
# derives the same names (rg-<app>-<env>, app-<app>-<env>, ...) so it never
# needs per-resource name inputs.
locals {
  base = "${var.app}-${var.environment}"

  # Azure storage accounts / key vaults: no dashes, length limits
  compact = substr(replace(lower("${var.app}${var.environment}"), "-", ""), 0, 18)

  tags = merge({
    app         = var.app
    environment = var.environment
    owner       = var.owner
    cost-center = var.cost_center
    managed-by  = "terraform"
    repository  = "arfandipulungan/xtramilesolution"
  }, var.extra_tags)
}
