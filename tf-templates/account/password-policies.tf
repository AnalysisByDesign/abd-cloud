# --------------------------------------------------------------------------------------------
# Configure the account password policies
# - we do not configure these through variables, as they are corporate policy
# --------------------------------------------------------------------------------------------

# Configure password policy based on sensible defaults
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = var.minimum_password_length
  password_reuse_prevention      = var.password_reuse_prevention
  require_lowercase_characters   = var.require_lowercase_characters
  require_uppercase_characters   = var.require_uppercase_characters
  require_numbers                = var.require_numbers
  require_symbols                = var.require_symbols
  allow_users_to_change_password = var.allow_users_to_change_password
  hard_expiry                    = var.hard_expiry
}
