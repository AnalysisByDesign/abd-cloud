#!/bin/bash

# -------------------------------------------------------------
# Autoscale deployment via desired capacity script - could do with some enhancing!
# Use the relevant setting for 'profile' when performing
# actions against AWS.

# -------------------------------------------------------------
# If using cross-account roles, have the following 
# configuration in ~/.aws/credentials
#
#   [auth_account]
#   aws_access_key_id = {your_access_key_here}
#   aws_secret_access_key = {your_secret_key_here}
#   aws_default_region = eu-west-1
#   
#   [account_1]
#   role_arn:arn:aws:iam::account_id:role/admins
#   source_profile=auth_account
#   
#   [account_2]
#   role_arn:arn:aws:iam::account_id:role/admins
#   source_profile=auth_account
# -------------------------------------------------------------
# If using specific user accounts, have the following 
# configuration in ~/.aws/credentials
#
#   [account_1]
#   aws_access_key_id = {your_access_key_here}
#   aws_secret_access_key = {your_secret_key_here}
#   aws_default_region = eu-west-1
#   
#   [account_2]
#   aws_access_key_id = {your_access_key_here}
#   aws_secret_access_key = {your_secret_key_here}
#   aws_default_region = eu-west-1
# -------------------------------------------------------------

profile=$1
asg_name=$2

region=eu-west-1
sleep=180

# Get the list of instances in the ASG
capacity=`aws autoscaling describe-auto-scaling-groups \
      --auto-scaling-group-name ${asg_name} \
      --no-paginate \
      --region ${region} \
      --profile ${profile} |
  jq -r '.AutoScalingGroups[].DesiredCapacity'`

new_capacity=$(( capacity * 2 ))

echo "Setting desired capacity for ${asg_name} to ${new_capacity}"

aws autoscaling set-desired-capacity \
    --auto-scaling-group-name ${asg_name} \
    --desired-capacity ${new_capacity} \
    --honor-cooldown \
    --region ${region}  \
    --profile ${profile}

echo Sleeping ${sleep} seconds...
sleep ${sleep}

echo "Setting desired capacity for ${asg_name} to ${capacity}"

aws autoscaling set-desired-capacity \
    --auto-scaling-group-name ${asg_name} \
    --desired-capacity ${capacity} \
    --honor-cooldown \
    --region ${region}  \
    --profile ${profile}
