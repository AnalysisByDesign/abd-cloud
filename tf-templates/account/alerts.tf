# --------------------------------------------------------------------------------------------
# Alerting SNS Topic
# Account-wide topic for CloudWatch alarm notifications. Subscriptions (e.g. email) are
# added manually, as email subscriptions need confirming by the recipient anyway.
# --------------------------------------------------------------------------------------------

resource "aws_sns_topic" "alerts" {
  count = var.alerts_topic_name != "" ? 1 : 0

  name = var.alerts_topic_name

  tags = merge(local.common_tags, var.alerts_tags)
}

# EventBridge rules (e.g. ECS deployment failures) can only publish to the topic if its
# policy allows events.amazonaws.com. Setting a policy replaces the default one, so the
# account-owner statement is restated here.
data "aws_iam_policy_document" "alerts" {
  count = var.alerts_topic_name != "" && var.alerts_allow_eventbridge ? 1 : 0

  statement {
    sid = "AccountOwner"
    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
    ]
    resources = [aws_sns_topic.alerts[0].arn]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid       = "EventBridgePublish"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.alerts[0].arn]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "alerts" {
  count = var.alerts_topic_name != "" && var.alerts_allow_eventbridge ? 1 : 0

  arn    = aws_sns_topic.alerts[0].arn
  policy = data.aws_iam_policy_document.alerts[0].json
}
