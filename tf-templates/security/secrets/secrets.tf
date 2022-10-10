# -----------------------------------------------------------------------------
# Prepare Secrets Manager
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Application RDS connectivity
module "db-username" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/secret-store"

  required    = var.require_db ? 1 : 0
  key         = "${local.vpc_name}/${var.component_name}/database/username"
  value       = "db_username"
  description = "The application RDS user name"
  tags        = local.common_tags
}

module "db-password" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/secret-store"

  required    = var.require_db ? 1 : 0
  key         = "${local.vpc_name}/${var.component_name}/database/password"
  value       = "db_password"
  description = "The application RDS user password"
  tags        = local.common_tags
}
