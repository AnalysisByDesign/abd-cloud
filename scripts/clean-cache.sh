#!/bin/bash
# --------------------------------------------------------------------------------
# Script name  : clean-cache.sh
# Author       : Dave Rix (dave@analysisbydesign.co.uk)
# Created      : 2018-06-06
# Description  : This script can be used to clean all Terraform cache folders
#              : which are the .terraform folders within the build folders
# History      :
#  2018-12-04  : DAR - Initial script
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Variable Declaration and includes
# --------------------------------------------------------------------------------

scriptDesc="Clean all Terraform cache folders"

# Include bash function library first
workPath=`dirname $0`
basePath=`git rev-parse --show-toplevel`
funcPath="${basePath}/funcs"

tmpPath=/tmp

source ${funcPath}/bash_funcs.sh

recurse="N"
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Local functions
# --------------------------------------------------------------------------------
function script_usage() {

  cat << EOF

Usage: 
        $0 [ OPTIONS ] target_folder

Options:
        -h                Show this message
        -r                Recursively delete all folders

Example:
        $0  -r  config/ringgo-dev

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
while getopts ":r" OPTION
do
  case $OPTION in
    r)
      recurse="Y"
      ;;
    ?)
      script_usage
      ;;
  esac
done
shift $((OPTIND - 1))

target=$1

if [ "${target}" = "" ]; then
  log_message "No target build folder supplied, exiting."
  script_cleanup 1
fi
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# We are ready to start, so check and set the lock file
# obtain_lock
# --------------------------------------------------------------------------------
log_message "Locating Terraform cache folders to remove"

depth="-maxdepth 1"
[ "${recurse}" = "Y" ] && depth=""

folders=`find ${target} ${depth} -name .terraform -print`

if [ "${folders}" = "" ]; then
  log_message "No Terraform cache folders found."
  script_cleanup 1
fi

for f in ${folders}; do

  log_message "    - removing ${f}"
  rm -rf ${f} 2>/dev/null

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

