#!/bin/bash
# --------------------------------------------------------------------------------
# Script name  : monitor-all.sh
# Author       : Dave Rix (dave@analysisbydesign.co.uk)
# Created      : 2018-06-06
# Description  : This script can be used to monitor the progress of tf-run-all.sh
# History      :
#  2018-06-06  : DAR - Initial script
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Variable Declaration and includes
# --------------------------------------------------------------------------------

scriptDesc="Monitor all Terraform runs"

# Include bash function library first
tmpPath=/tmp
basePath=`git rev-parse --show-toplevel`
funcPath="${basePath}/funcs"
source ${funcPath}/bash_funcs.sh

# Set some defaults
scriptSleep=2   # How long are we sleeping for during the script
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Local functions
# --------------------------------------------------------------------------------
function script_usage() {

  cat << EOF

Usage: 
        $0 [ OPTIONS ]

Options:
        -h                Show this message
        -s n              Sleep n seconds

Example:
        $0
        $0 -s 5

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
while getopts ":vs:d" OPTION
do
  case $OPTION in
    s)
      scriptSleep=${OPTARG}
      ;;
    ?)
      script_usage
      ;;
  esac
done
shift $((OPTIND - 1))

# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# We are ready to start, so check and set the lock file
# obtain_lock
# --------------------------------------------------------------------------------
echo ""
echo "Extracting final entries across all build.log files"

tmpOutput=/tmp/monitor-all.$$
while [ 1 -eq 1 ]; do

  rm ${tmpOutput} 2>/dev/null

  for file in `find ${basePath}/logs/ -name build.log -print`; do

    grep "    -" ${file} | \
      tail -2 | head -1 | \
      grep -vE "^$" | \
      grep -v "state lock" | \
      grep -v "execution wrapper" | \
      sort -u | \
    while read line; do
      echo ${line} >> ${tmpOutput}
    done

  done

  clear
  date
  sort --field-separator="," --key=1 ${tmpOutput}

  sleep ${scriptSleep}
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

