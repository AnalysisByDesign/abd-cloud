# --------------------------------------------------------------------------------------------
# Key pairs
# --------------------------------------------------------------------------------------------
module "ssh-key-pair" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/ssh-key"

  # Required variables
  name            = format("%s-%s", local.vpc_name, var.asg_ssh_key_name)
  public_key_file = var.asg_ssh_public_key_file
}
