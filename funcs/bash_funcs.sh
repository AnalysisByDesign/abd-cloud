#!/bin/bash

################################################################################
# Set up any functions that might be required in our scripts
################################################################################
scriptName=`basename $0 2>/dev/null`
[ "" = "${verbose}" ] && verbose="N"

   userIP=`echo ${SSH_CLIENT} | awk '{print $1}'`
  theDate=`date +"%Y%m%d"`
  theTime=`date +"%H%M%S"`
 dateTime=`date +"%Y-%m-%d,%H:%M:%S"`
   theDTS=`date +"%Y-%m-%d-%H-%M-%S"`
startTime=`date +"%s"`

################################################################################
# If we have no console to write to, always output to a logfile instead
if [[ $- == *i* ]]; then
    if [ "${logfile}" = "" ]; then
        mkdir -p /tmp/log/${scriptName}
        logfile="/tmp/log/${scriptName}/${theDate}.log"
    fi
    # Close STDOUT & STDERR FD
    exec 1<&-; exec 2<&-
    # Redirect STDOUT & STDERR to logfile
    exec 1>>${logfile}; exec 2>>${logfile}
fi

################################################################################
# Colour combinations for message output, based on syslog severity levels
COLOUR_EMERG='\033[1;41m'   # Invert Red
COLOUR_ALERT='\033[1;41m'   # Invert Red
COLOUR_CRIT='\033[1;31m'    # Red
COLOUR_ERR='\033[0;31m'     # Red
COLOUR_WARNING='\033[1;33m' # Yellow
COLOUR_NOTICE='\033[0;32m'  # Green
COLOUR_INFO='\033[0m'       # No colour
COLOUR_DEBUG='\033[0m'      # No colour
COLOUR_NONE='\033[0m'       # No colour

################################################################################
# Now set up any functions that might be required in our scripts
################################################################################

# include the AWS functions that are being bulit up
[ "" = "${basePath}" ] && basePath=`git rev-parse --show-toplevel`
[ "" = "${funcPath}" ] && funcPath="${basePath}/funcs"
[ "" = "${tfAssets}" ] && tfAssets="${basePath}/tf-assets"
. "${funcPath}"/bash_aws_funcs.sh

################################################################################
# obtain_lock - Obtains a lock file based on the calling program name...
function obtain_lock () {

  # Make sure we use a specific lock file for the targetted instance if possible
  [ "" = "${lockFile}" ] && lockFile="/tmp/${scriptName}.lock"

  log_verbose "Locking with ${lockFile}"

  if [ -f /usr/bin/lockfile ]
  then
    # We can use the procmail lockfile script :)

    # Have we been passed in a lock timeout value
    [ "" != "$1" ] && locktimeout="-l $1"

    # Attempt to create the lock file
    /usr/bin/lockfile -8 -r 5 ${locktimeout} ${lockFile}
    lockStatus=$?

  else
    # We have to resort to a legacy method

    # Attempt to create the lock file
    touch ${lockFile} 2>/dev/null
    lockStatus=$?

  fi

  if [ ${lockStatus} -ne 0 ]
  then
    log_message "Obtaining lockfile ${lockFile} failed... - already running?"
    exit -1
  fi

}

################################################################################
# release_lock - Obtains a lock file based on the calling program name...
function release_lock () {

  [ -f "${lockFile}" ] && /bin/rm -f "${lockFile}" > /dev/null 2>&1

}

################################################################################
# check_status - Validates status inputs for messages
function check_status () {

  THE_COLOUR="${COLOUR_NONE}"
  case ${1:-info} in
    emerg)   echo ${COLOUR_EMERG}   ; return 0;;
    alert)   echo ${COLOUR_ALERT}   ; return 0;;
    crit)    echo ${COLOUR_CRIT}    ; return 0;;
    err)     echo ${COLOUR_ERR}     ; return 0;;
    warning) echo ${COLOUR_WARNING} ; return 0;;
    notice)  echo ${COLOUR_NOTICE}  ; return 0;;
    info)    echo ${COLOUR_INFO}    ; return 0;;
    debug)   echo ${COLOUR_DEBUG}   ; return 0;;
    ?)       echo ${COLOUR_WARNING} ; return 0;;
  esac

}

################################################################################
# log_syslog - Writes a message to the syslog...
function log_syslog () {

  [ "${3}" = "" ] && msgType="bash/${scriptName}"

  logger -p "user.${2:-info}" -t "${3}" "${1}"
}

################################################################################
# log_message - Displays the input parameter with a date/time stamp prefix
function log_message () {
  thedate=`date +"%Y-%m-%d %H:%M:%S"`

  # Check the incoming message status
  THE_COLOUR=`check_status ${2}`

  # Write any marked as emerg, alert, crit, err or warning to stderr
  chk=`echo ${2} | grep -e "emerg|alert|crit|err|warning"`
  if [ "${chk}" != "" ]; then
    echo -e "${thedate},${THE_COLOUR}${1}${COLOUR_NONE}" >&2
  else
    echo -e "${thedate},${THE_COLOUR}${1}${COLOUR_NONE}"
  fi

  # And write to the logfile if one is specified
  [ "${logfile}" != "" ] && echo "${thedate},${1}" >> ${logfile}

  # And send the output to syslog too
  log_syslog "${1}" "${2}" "${3}"
}

################################################################################
# log_verbose - Displays the input parameter with a date/time stamp prefix
#             if the relevant variable is set
function log_verbose () {
  if [ "Y" = "${verbose}" -o "Y" = "${v_verbose}" ]
  then
    # This is a 'verbose' debug statement
    [ "${3}" = "" ] && msgType="bash/${scriptName}/verbose"
    log_message "${1}" "info" "${3}"
  fi
}


################################################################################
# log_v_verbose - Displays the input parameter with a date/time stamp prefix
#             if the relevant variable is set
function log_v_verbose () {
  if [ "Y" = "${v_verbose}" ]
  then
    # This is a 'very verbose' debug statement
    # Print only if v_verbose is set
    [ "${3}" = "" ] && msgType="bash/${scriptName}/v_verbose"
    log_message "${1}" "debug" "${3}"
  fi
}


################################################################################
# microtime - returns a highly accurate time-stamp for monitoring purposes
function microtime() {
  date +"%s.%N"
}


################################################################################
# get_duration - returns the difference between two times
function get_duration() {
  startT=$1
  endT=$2

  # Check what we have received
  # and if we have no start time - cannot calc duration
  if [ "${startT}" = "" ]
  then
    echo "n/a"
    return
  fi

  # If we have no end time - use current time
  if [ "${endT}" = "" ]
  then
    endT=`microtime`
  fi

  # Now do some calculation and return the duration
  echo $(( endT - startT + 0 ))

}


################################################################################
# dec2ip - takes a decimal number and turns it into an IP address
function dec2ip() {
  theDec=$1
  theIP=`gawk 'BEGIN {
      dec = ARGV[1]
      for (e = 3; e >= 0; e--) {
    octet = int(dec / (256 ^ e))
    dec -= octet * 256 ^ e
    ip = ip delim octet
    delim = "."
      }
      printf("%s\n", ip)
  }' ${theDec}`
  echo ${theIP}
}

################################################################################
# ip2dec - takes a decimal number and turns it into an IP address
function ip2dec() {
  theIP=$1
  theDec=`gawk 'BEGIN {
      ip = ARGV[1]
      split(ip, octets, ".")
      for (i = 1; i <= 4; i++) {
    dec += octets[i] * 256 ** (4 - i)
      }
      printf("%i\n", dec)
  }' ${theIP}`
  echo ${theDec}
}

################################################################################
# Function to return the account name if passed in an account number
# This relies on the account list being prepared correctly
acct_list=()
function get_account_name() {
  acct_name=""
  for acct in ${acct_list[@]}; do
    acct_number=`echo ${acct} | cut -d":" -f1 | tr -d " "`
    if [ "${acct_number}" = "${1}" ]; then
      acct_name=`echo ${acct} | cut -d":" -f2 | tr -d " "`
    fi
  done
  echo ${acct_name}
}

################################################################################
# Check how many occurances of a script we are already running and wait
# for some to complete if there are too many
function wait_for_slot() {
  waitForScript=$1
  waitForCount=$2
  rotateLoop=("-" "\\" "|" "/")

  count=0; echo -n ""
  numRunning=`ps -ef | grep ${waitForScript} | grep -v grep | wc -l | awk '{print $0+0}'`
  while [ ${numRunning} -ge ${waitForCount} ]
  do
    echo -en "\r ${rotateLoop[count % 4]} waiting for available execution slot..."
    sleep 0.05
    numRunning=`ps -ef | grep ${waitForScript} | grep -v grep | wc -l | awk '{print $0+0}'`
    count=$((count + 1))
  done
  echo -en "\r"
}

################################################################################
# Env file format to be used by the next few functions
# 1 - seq , 2 - protect , 3 - prevent , 4 - environment
################################################################################

# Where is our environment descriptor file - this could eventually be in a DB
envFiles=${tfAssets}/*.csv

# Check protect status of a build location
function is_protected() {
  # Check the target plus descendents for the protect flag
  protect=`grep -hE ",${1}" ${envFiles} | cut -d"," -f2 | sort -u`
  [ "${protect}" != "" ] && echo "Y"
  echo ""
}

# Check prevent status of a build location
function is_prevented() {
  # Check the target for the protect flag
  prevent=`grep -hE ",${1}$" ${envFiles} | cut -d"," -f3`
  [ "${prevent}" != "" ] && echo "Y"
  echo ""
}

# Return a list of all ancestors of the selected target build location
function get_ancestors() {
  bPath="."
  for chkBuild in `echo ${1} | sed "s/\// /g"`; do
    bPath="${bPath}/${chkBuild}"
    grep -hE ",${bPath:2}$" ${envFiles} | cut -d"," -f1,4
  done
}

# Return a list of all decendents of the selected target build location
function get_descendents() {
  grep -hE ",${1}" ${envFiles} | cut -d"," -f1,4
}
################################################################################
