# --------------------------------------------------------------------------------------------
# Remote access authentication for NewRelic
# --------------------------------------------------------------------------------------------

# Create automation role and allow to be attached to EC2 instance
# Only if this role needs to assume remote account roles
module "newrelic_role" "newrelic" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/iam-role"

  required = var.newrelic_required

  roles = [{
    name               = "NewRelicInfrastructure-Integrations"
    description        = "Allows remote monitoring by NewRelic"
    assume_role_policy = "${data.aws_iam_policy_document.newrelic.json}"
    policy_arn         = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  }]
}
