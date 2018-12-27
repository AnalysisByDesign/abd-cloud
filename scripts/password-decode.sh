#!/bin/bash
# --------------------------------------------------------------------------------
# Script name  : password-decode.sh
# Author       : Dave Rix (dave@analysisbydesign.co.uk)
# Created      : 2018-07-10
# Description  : This script decodes passwords for users built through Terraform
# History      :
#  2018-07-10  : DAR - Initial script
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Variable Declaration and includes
# --------------------------------------------------------------------------------

scriptDesc="Decode Terraform generated user passwords"

# Include bash function library first
workPath=`dirname $0`
basePath=`git rev-parse --show-toplevel`
funcPath="${basePath}/funcs"
tmpPath=/tmp

. ${funcPath}/bash_funcs.sh

# Set some defaults
[[ "${verbose}" = "" ]] && verbose="N"
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Local functions
# --------------------------------------------------------------------------------
function script_usage() {

  cat << EOF

Usage: 
        $0 [ OPTIONS ]  password.file

Options:
        -h                Show this message
        -v                Verbose output

Example:
        $0 passwords.txt

EOF

  # If we have called the usage statement, then something has gone wrong
  # so we can remove the lock file ready for the next run!
  script_cleanup 1
}

# The exit_script function will be used to catch unwanted exits of the script
# and to perform any cleanups
function script_exit() {
  log_message "Exiting ${scriptDesc} due to early termination..."
  script_cleanup 1
}

# This is the cleanup function, do remove temp files and others
function script_cleanup() {
  ret=$1
  log_verbose "Running cleanup function for ${scriptDesc}"
  endTime=`date +"%s"`
  duration=`get_duration $startTime $endTime`
  # Remove temp files here
  rm -f ${tmpOutput}
  log_verbose "Exiting ${scriptDesc} - duration ${duration} seconds."
  release_lock
  exit $ret
}

# Now set up a trap to catch any errors and cause the exit early function to be
# called we will trap the following codes HUP, INT, QUIT, TERM
trap script_exit HUP INT QUIT TERM
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Preliminary checks
# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Check which options have been passed in
# --------------------------------------------------------------------------------
while getopts ":v" OPTION
do
  case $OPTION in
    v)
      verbose="Y"
      ;;
    ?)
      script_usage
      ;;
  esac
done
shift $((OPTIND - 1))

passwordFile=$1

# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# We are ready to start, so check and set the lock file
# obtain_lock
# --------------------------------------------------------------------------------
log_message "Decoding passwords"
log_message "Use when logging in to the AWS console at"
log_message "    - https://px-authentication.signin.aws.amazon.com/console "
log_message ""

cat ${passwordFile} | \
while read line; do

  user=`echo ${line} | awk '{print $1}'`
  hash=`echo ${line} | awk '{print $3}'`

  log_message "  - checking ${user}"

  # Ensure we get any errors present in the following pipeline command
  set -o pipefail; password=`echo ${hash} | base64 --decode | keybase pgp decrypt 2>/dev/null`

  ret=$?
  if [ ${ret} != 0 ]; then
    log_message "    - something has gone wrong, ensure that keybase command is available"
  fi

  log_message "    - password = ${password}"

done

# --------------------------------------------------------------------------------
# Logging, analysis, email output, etc.
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# All done, so tidy stuff up a bit before exiting...
script_cleanup
# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------
#      SCRIPT END
# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------

