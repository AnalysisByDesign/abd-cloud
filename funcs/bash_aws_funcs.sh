#!/bin/bash
# --------------------------------------------------------------------------------
# Script name  : bash_aws_funcs.sh
# Author       : Dave Rix (dave@analysisbydesign.co.uk)
# Created      : 2018-04-26
# Description  : Some useful functions to interrogate various AWS bits
# History      :
#  2018-04-26  : DAR - Initial script
# --------------------------------------------------------------------------------

# get the path this library sits in
thisPath=`dirname ${BASH_SOURCE[0]}`

# and specify the AWS region required by the CLI tools
export AWS_DEFAULT_REGION="eu-west-2"

# --------------------------------------------------------------------------------
# Get list of available MySQL encrypted login-path names
function get_login_path_list() {
	mysql_config_editor print --all | grep -E "^\[" | sed "s/\[/    /g" | sed "s/\]//g" | sort -u
}

# --------------------------------------------------------------------------------
# Get the current VPC identifier
function get_current_vpc() {
	# get the instance id of this host
	instanceId=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
	# Now get the VPC this host is in
	thisVPC=`aws ec2 describe-instances --instance-ids "${instanceId}" --output json | \
				jq -r '.Reservations[].Instances[].VpcId'`
	# Return the value, excluding the quotes
	echo ${thisVPC}
}

# --------------------------------------------------------------------------------
# Get the current VPC name
function get_current_vpc_name() {
	# get the VPC identifier
	VPCid=`get_current_vpc`
	VPCname=`aws ec2 describe-vpcs --vpc-id ${VPCid} | \
				jq -r '.Vpcs[0].Tags[0].Value'`
	echo ${VPCname}
}

# --------------------------------------------------------------------------------
# This function gets the route table id for the rout table called '{vpc_name} private'
function get_private_route_table_id() {
	# Get the current VPC id
	thisVPC=`get_current_vpc`
	# Get the tag value for the private route table
	thisTag=`aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${thisVPC}" | \
			grep private | cut -d"\"" -f4`
	# Now get the route id
	thisRoute=`aws ec2 describe-route-tables --filters "Name=vpc-id,Values=${thisVPC}" "Name=tag:Name,Values=${thisTag}" | \
			jq -r '.RouteTables[].RouteTableId'`
	# Return the value, excluding the quotes
	echo ${thisRoute}
}

# --------------------------------------------------------------------------------
# Get all RDS instance names in the current VPC
function get_rds_instance_names() {
	# Get the current VPC id
	thisVPC=`get_current_vpc`
	# Now return all the RDS instance names for this VPC
	aws rds describe-db-instances --output json 2>/dev/null | \
		jq -c '.DBInstances[] | if ( .Engine == "mysql" ) then {(.DBSubnetGroup.VpcId): .DBInstanceIdentifier} else empty end' | \
		cut -d"\"" -f4
}

# --------------------------------------------------------------------------------
# Get the RDS host for a supplied MySQL login-path
function get_rds_host() {
	rdsInstance=$1
	if [ "" != "${rdsInstance}" ]; then
		host=`mysql_config_editor print --login-path=${rdsInstance} | \
				grep "host" | awk '{print $3}'`
	fi
	echo ${host}
}

# --------------------------------------------------------------------------------
# Get the RDS instance name from a supplied MySQL login-path
function get_rds_instance_name() {
	rdsInstance=$1
	if [ "" != "${rdsInstance}" ]; then
		instanceName=`aws rds describe-db-instances --db-instance-identifier "${rdsInstance}" --output json 2>/dev/null | \
				jq -r '.DBInstances[].DBInstanceIdentifier'`
	fi
	echo ${instanceName}
}

# --------------------------------------------------------------------------------
# Get the RDS instance availability from a supplied MySQL login-path
function get_rds_instance_availability() {
	rdsInstance=$1
	if [ "" != "${rdsInstance}" ]; then
		instanceAvail=`aws rds describe-db-instances --db-instance-identifier "${rdsInstance}" --output json 2>/dev/null | \
				jq -r '.DBInstances[].DBInstanceStatus'`
	fi
	echo ${instanceAvail}
}

# --------------------------------------------------------------------------------
# Get the AWS region from the RDS instance
function get_rds_region() {
	rdsInstance=$1
	if [ "" != "${rdsInstance}" ]; then
		region=`get_rds_endpoint "${rdsInstance}" | rev | cut -d. -f4 | rev`
	fi
	echo ${region}
}

# --------------------------------------------------------------------------------
# Get the endpoint from the RDS instance
function get_rds_endpoint() {
	rdsInstance=$1
	if [ "" != "${rdsInstance}" ]; then
		endpoint=`aws rds describe-db-instances --db-instance-identifier "${rdsInstance}" --output json 2>/dev/null | \
				jq -r '.DBInstances[].Endpoint.Address'`
	fi
	echo ${endpoint}
}

# --------------------------------------------------------------------------------
# Get RDS tags in a format to allow them to be applied toanother instance
function get_rds_tags() {
	rdsInstance=$1
	if [ "" != "${rdsInstance}" ]; then
		# First we need the instanceName :)
		theInstanceName=`get_rds_instance_name ${rdsInstance}`
		# and the region
		region=`get_rds_region ${rdsInstance}`
		# Now we can get the tags
		instanceTags=`get_rds_resource_tags "db" ${region} ${theInstanceName}`

	fi
	echo ${instanceTags}
}

# --------------------------------------------------------------------------------
# Get resource tags in a format to allow them to be applied to another instance
function get_rds_resource_tags() {
	resourceType=$1
	resourceRegion=$2
	resourceName=$3
	if [ "" != "${resourceName}" ]; then
		# Now we can get the tags
		instanceTags=`aws rds list-tags-for-resource \
				--resource-name arn:aws:rds:${resourceRegion}:${awsAccount}:${resourceType}:${resourceName} 2>/dev/null`
		# Unfortunately they are not in a nice format...
		instanceTags=`echo ${instanceTags} | cut -d"[" -f2- | rev | cut -d"]" -f2- | rev`
		instanceTags="[${instanceTags}]"

	fi
	echo ${instanceTags}
}

# --------------------------------------------------------------------------------
# Get latest snapshot for a given RDS instance name
function get_rds_latest_snapshot() {
	instance=$1
	# First, get all the snapshots for the supplied instance
	# we can filter these later, and be selective if required
	# The instance does not need to be available to get this info
	allSnaps=`aws rds describe-db-snapshots --db-instance-identifier ${instance} --output json 2>/dev/null | \
			${thisPath}/py/rds_latest_snapshot.py`
	# Output : SnapTime, SnapName, SnapType
	#    Eg. : 2015-10-27T02:59:54.049Z,rds:isntance-name-2015-10-27-02-59,automated
	echo ${allSnaps}
}

# --------------------------------------------------------------------------------
# Wait for a particular snapshot to become available, this has an additional loop
# as the standard CLI wait will only a short period of time
function wait_for_rds_snapshot() {
	snapshotName=$1
	# Get the optional loop count, and set to 10 if not supplied
	optLoopCount=$2
	[ "" = "${optLoopCount}" ] && optLoopCount=10
	# Prepare the loop
	count=0
	while [ 1 -eq 1 ]; do
		count=$((count + 1))
		aws rds wait db-snapshot-completed --db-snapshot-identifier ${snapshotName} >/dev/null 2>&1
		# Mark as complete if successfull
		[ 0 -eq $? ] && return 0
		sleep 10
		# Have we tried 10 times, and still failed?
		if [ ${optLoopCount} -le ${count} ]; then
			TP_Message "Snapshot not marked as complete after 10 attempts at 'wait' ${optLoopCount} x (40x15) seconds."
			return 1
		fi
	done
}

# --------------------------------------------------------------------------------
# Wait for a particular instance to become available, this has an additional loop
# as the standard CLI wait will only a short period of time
function wait_for_rds_instance() {
	instanceName=$1
	# Get the optional loop count, and set to 10 if not supplied
	optLoopCount=$2
	[ "" = "${optLoopCount}" ] && optLoopCount=10
	# Prepare the loop
	count=0
	while [ 1 -eq 1 ]; do
		count=$((count + 1))
		aws rds wait db-instance-available --db-instance-identifier ${instanceName} >/dev/null 2>&1
		# Mark as available if successfull
		[ 0 -eq $? ] && return 0
		sleep 10 
		# Have we tried 10 times, and still failed?
		if [ ${optLoopCount} -le ${count} ]; then
			TP_Message "Instance not marked as available after 10 attempts at 'wait' ${optLoopCount} x (40x15) seconds."
			return 1
		fi
	done
}

# --------------------------------------------------------------------------------
# List all s3 buckets by name and grep output for a provided pattern
function get_s3_buckets_by_pattern() {
	grepPattern=$1
	bucketName=`aws s3api list-buckets --query 'Buckets[].Name' | grep -e "${grepPattern}" |  cut -d'[' -f2 | cut -d']' -f1 | cut -d'"' -f2`
	if [ ${#bucketName[@]} -eq 0 ]; then
		TP_Message "Could not match any S3 buckets with the pattern [ ${grepPattern} ]"
		return 1
	fi
	echo ${bucketName}
}

# --------------------------------------------------------------------------------
# Template - 12 lines
function template() {
	rdsInstance=$1
	if [ "" != "${rdsInstance}" ]; then
		host=`mysql_config_editor print --login-path=${rdsInstance} 2>/dev/null | \
			grep host | \
			awk '{print $3}'`
	fi
	echo ${host}
}

# --------------------------------------------------------------------------------
