#!/bin/bash
# --------------------------------------------------------------------------------
# Script name  : clone-config.sh
# Author       : Dave Rix (dave@analysisbydesign.co.uk)
# Created      : 2018-06-06
# Description  : This script can clone a build folder and all sub-folders
#              : it will also tidy up all Terraform cache folders
# History      :
#  2018-12-04  : DAR - Initial script
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Variable Declaration and includes
# --------------------------------------------------------------------------------

scriptDesc="Clone Terraform configuration structure"

# Include bash function library first
workPath=`dirname $0`
basePath=`git rev-parse --show-toplevel`
funcPath="${basePath}/funcs"

tmpPath=/tmp

source ${funcPath}/bash_funcs.sh

# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Local functions
# --------------------------------------------------------------------------------
function script_usage() {

  cat << EOF

Usage: 
        $0 [ OPTIONS ] source_folder target_folder

Options:
        -h                Show this message

Example:
        $0  config/ringgo-dev/permitproof config/ringgo-dev/oauth

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
while getopts ":" OPTION
do
  case $OPTION in
    ?)
      script_usage
      ;;
  esac
done
shift $((OPTIND - 1))

source=$1
target=$2

if [ "${target}" = "" ]; then
  log_message "Not enough parameters supplied, exiting."
  script_cleanup 1
fi

if [ ! -d "${source}" ]; then
  log_message "No valid source build folder supplied, exiting."
  script_cleanup 1
fi

if [ -d "${target}" ]; then
  log_message "Target folder already exists, exiting."
  script_cleanup 1
fi

# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# We are ready to start, so check and set the lock file
# obtain_lock
# --------------------------------------------------------------------------------
log_message "Examining folders to clone"

tree -d ${source}

log_message "Are you sure you want to clone this folder? (Yy) "
read ans

if [ "${ans}" = "Y" -o "${ans}" = "y" ]; then

  # Clone the source folder
  cp -Rp ${source} ${target}

  # Now clean up the Terraform cache folders
  find ${target} -name .terraform -exec rm -r {} \; 2>/dev/null

fi

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

