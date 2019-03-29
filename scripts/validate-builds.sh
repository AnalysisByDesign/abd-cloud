#!/bin/bash
# --------------------------------------------------------------------------------
# Script name  : validate-builds.sh
# Author       : Dave Rix (dave@analysisbydesign.co.uk)
# Created      : 2018-07-03
# Description  : This script validates all build locations have an environment entry
# History      :
#  2018-07-03  : DAR - Initial script
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Variable Declaration and includes
# --------------------------------------------------------------------------------

scriptDesc="Validate all build locations"

# Include bash function library first
tmpPath=/tmp
basePath=`git rev-parse --show-toplevel`
funcPath="${basePath}/funcs"
source ${funcPath}/bash_funcs.sh

# Set some defaults
[[ "${verbose}" = "" ]] && verbose="N"
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
        -v                Verbose output

Example:
        $0

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
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
log_message "Checking for duplicates"
dupFile=${tmpPath}/dupCheck.$$

cd ${basePath}
sort ${sequenceFiles} | 
      grep -vE "^#" | 
      grep -vE "^ *$" | 
      uniq -c | 
      grep -vE "^ +1 " | sort -rn > ${dupFile}

numDupes=`wc -l ${dupFile} | awk '{print $1 + 0}'`

if [ ${numDupes} -ne 0 ]; then
  log_message "    - found ${numDupes} duplicates"
  cat ${dupFile}
  log_message "    - end of duplicates"
fi

# --------------------------------------------------------------------------------
log_message "Validating all build locations"

cd ${configPath}
pathlist=`find . -name "*_config.*" -print |
            rev | cut -d"/" -f2- | rev | sort -u`

for env in ${pathlist}; do

  log_verbose "  - checking ${env}"

  line=`grep ${env} ${sequenceFiles}`

  if [ "${line}" = "" ]; then

    log_message "MISSING - ${env}"

    echo "9999,protect,prevent,${env}" >&2

  fi

done

# --------------------------------------------------------------------------------
log_message "Validating all build files"

cd ${basePath}
pathlist=`sort -u ${sequenceFiles} |
            grep -vE "^#" | 
            grep -vE "^ *$" | 
            cut -d"," -f4 | sort -u`
for env in ${pathlist}; do

  log_verbose "  - checking ${env}"

  if [ ! -d ${env} ]; then

    log_message "EXTRA - ${env}"
    grep -H "${env}$" ${sequenceFiles}

  fi

done

# --------------------------------------------------------------------------------
log_message "Validating all build folders are required"

cd ${basePath}
pathlist=`find ${configPath} -type d | grep -v .terraform`

for env in ${pathlist}; do

  log_verbose "  - checking ${env}"

  if [ ! -f ${env}/*_config.sh -o ! -f ${env}/*_config.tfvars ]; then

    # Additional check for 'normal' files (not folders)
    files=`ls -1dp ${env}/* 2>/dev/null | grep -vE "\/$"`

    if [ "${files}" = "" ]; then
      log_message "NOT REQUIRED? - ${env}"
    fi

  fi

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

