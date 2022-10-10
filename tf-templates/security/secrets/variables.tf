# ============================================================================================
# Common parameters
# ============================================================================================

# Required ----------------------

variable "component_name" {
  description = "Name of component to insert into secrets path /{vpc}/{component_name}/..."
  type        = string
}

# Optional ----------------------

variable "require_db" {
  description = "Is a database username and password required"
  default     = false
}

# ============================================================================================
#                                      End of Variable Declarations
# ============================================================================================

