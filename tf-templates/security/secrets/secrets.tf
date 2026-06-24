# -----------------------------------------------------------------------------
# Secrets Store
# -----------------------------------------------------------------------------

module "secret" {
  for_each = var.secrets
  source   = "../../../../abd-cloud-modules/security/secret-store"

  key         = each.key
  value       = each.value.value
  description = each.value.description
  type        = each.value.type
  tags        = merge(local.common_tags, each.value.tags)
}
