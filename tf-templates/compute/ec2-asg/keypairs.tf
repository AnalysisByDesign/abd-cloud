# --------------------------------------------------------------------------------------------
# Key pairs
# --------------------------------------------------------------------------------------------
module "ssh-key-pair" {
  source = "../../../../abd-cloud-modules/security/ssh-key"

  # Required variables
  name            = format("%s-%s", local.vpc_name, var.asg_ssh_key_name)
  public_key_file = var.asg_ssh_public_key_file
}
