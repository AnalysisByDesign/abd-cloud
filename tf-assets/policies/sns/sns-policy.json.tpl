{
  "Id"       : "1",
  "Version"  : "2012-10-17",
  "Statement": [
    {
      "Sid"      : "1",
      "Effect"   : "Allow",
      "Principal": {
        "Service": "${principal}",
        "AWS": "arn:aws:iam::${acct_target}:root"
      },
      "Action"  : "SNS:Publish",
      "Resource": "arn:aws:sns:${region}:${acct_target}:${sns_topic}"
    },
    {
      "Sid"      : "2",
      "Effect"   : "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "SNS:Receive",
        "SNS:Subscribe",
        "SNS:GetTopicAttributes",
        "SNS:SetTopicAttributes",
        "SNS:ListSubscriptionsByTopic"
      ],
      "Resource" : "arn:aws:sns:${region}:${acct_target}:${sns_topic}",
      "Condition": {
        "StringEquals": {
          "AWS:SourceOwner": "${acct_target}"
        }
      }
    }
  ]
}