{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "*",
            "Resource": "arn:aws:s3:::${s3_name}/*"
        }
    ]
}
