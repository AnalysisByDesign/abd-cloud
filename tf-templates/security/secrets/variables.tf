# ============================================================================================
# Secrets configuration
# ============================================================================================

variable "secrets" {
  description = "Map of SSM Parameter Store entries to create. Each map key becomes the parameter path (/{key}). Values default to 'change_me' and are not overwritten by Terraform after initial creation."
  type = map(object({
    value       = optional(string, "change_me")
    description = optional(string, "")
    type        = optional(string, "String")
    tags        = optional(map(string), {})
  }))
  default = {}
}

# ============================================================================================
#                                      End of Variable Declarations
# ============================================================================================
