#!/bin/bash
# --------------------------------------------------------------------------------
# Script name  : tf-run-all.sh
# Author       : Dave Rix (dave@analysisbydesign.co.uk)
# Created      : 2016-04-26
# Description  : This script will run ALL the TF builds in the sequence defined in the config path
# History      :
#  2016-04-26  : DAR - Initial script
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Variable Declaration and includes
# --------------------------------------------------------------------------------

scriptDesc="Terraform bulk execution wrapper script"

# Include bash function library first
tmpPath=/tmp
logPath=/tmp/logs
basePath=`git rev-parse --show-toplevel`
funcPath="${basePath}/funcs"
logfile=${logPath}/$0.$$.log

source ${funcPath}/bash_funcs.sh

mkdir -p ${logPath}

# Set some defaults
[[ "${verbose}" = "" ]] && verbose="N"
[[ "${v_verbose}" = "" ]] && v_verbose="N"
dryRun="N"      # Do we want to perform the actions
scParallel=8    # How many parallel scripts to we want to run
tfParallel=10   # How many parallel terraform threads to run
buildFile="N"
cleanCache="N"
opts=""
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Local functions
# --------------------------------------------------------------------------------
function script_usage() {

    cat << EOF

Usage: 
        $0 [ OPTIONS ]  action  [ target ]

Options:
        -h                Show this message
        -d                Dry-run
        -c                Clean Terraform cache
        -m n              Max builds in parallel
        -t n              Max Terraform threads in parallel
        -v                Verbose output
        -vv               Very verbose output

Example:
        $0       plan    
        $0 -v -d apply   
        $0 -vvd  destroy 

EOF

    # If we have called the usage statement, then something has gone wrong
    # so we can remove the lock file ready for the next run!
    script_cleanup 1
}

# The exit_script function will be used to catch unwanted exits of the script
# and to perform any cleanups
function script_exit() {
    log_message "Exiting ${scriptDesc} due to early termination..." err
    log_message "This may not termiate all child processes..." err
    script_cleanup 1
}

# This is the cleanup function, do remove temp files and others
function script_cleanup() {
    ret=$1
    log_verbose "Running cleanup function for ${scriptDesc}"
    endTime=`date +"%s"`
    duration=`get_duration $startTime $endTime`
    # Remove temp files here
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
while getopts ":dcom:t:v" OPTION
do
        case $OPTION in
                c)
                        cleanCache="Y"
                        opts="${opts} -c"
                        ;;
                d)
                        dryRun="Y"
                        opts="${opts} -d"
                        ;;
                m)
                        scParallel=${OPTARG}
                        ;;
                t)
                        tfParallel=${OPTARG}
                        opts="${opts} -t ${tfParallel}"
                        ;;
                v)
                        [ "Y" = "${verbose}" ] && v_verbose="Y" && opts="${opts} -v"
                        verbose="Y"
                        ;;
                ?)
                        script_usage
                        ;;
        esac
done
shift $((OPTIND - 1))

# -----------------------------------------------------------------------------
# Validate the environment and the passed in parameters
# -----------------------------------------------------------------------------
action=$1
target=$2

# Validate the passed in action
options="init|fmt|graph|refresh|show|taint|plan|apply|destroy"
chk=`echo ${action} | egrep ${options}`
if [ "" = "${chk}" ]; then
    log_message "No valid action supplied." err
    script_cleanup 1
fi

# Are we running from a folder or a file location
if [ "${target}" != "" ]; then
    if [ -f ${target} ]; then
        log_message "Running against the file ${target}..."
        buildFile="Y"
    fi
fi

# Strip a trailing "/" and leading "./" if supplied
target=`echo ${target} | sed "s/\/$//" | sed "s/^\.\///"`
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# We are ready to start, so check and set the lock file
log_message "Starting ${scriptName} for ${target}..."
obtain_lock
log_verbose "Verbose logging     = ${verbose}"
log_verbose "V-verbose logging   = ${v_verbose}"
log_verbose "Dry-run             = ${dryRun}"
log_verbose "Lock file           = ${lockFile}"
log_verbose "Parralel TF threads = ${tfParallel}"
log_verbose "Parallel scripts    = ${scParallel}"
log_verbose "Build file          = ${buildFile} - ${target}"
# --------------------------------------------------------------------------------

if [ "destroy" = "${action}" ]; then
    reverse_sort="-r"
fi

if [ "${buildFile}" != "Y" ]; then

    # Default the build to the base ${configPath} location
    [ "${target}" = "" ] && target="${configPath}"

    # Now find a sorted list of all ancestors and decendents of our build target
    ancList=`get_ancestors ${target}`
    desList=`get_descendents ${target}`
    build_list="${ancList} ${desList}"

else

    # Extract the folder list to build from the build file
    build_list=`grep -vE "^#" ${target} | cut -d, -f1,4`

fi

# And build the sorted list to be processed
build_list=`echo ${build_list} | tr " " "\n" | sort -u -t"," -k1 ${reverse_sort}`

log_message "Initiating ${COLOUR_NOTICE}${action}${COLOUR_NONE} for all ${target} resources..."

# Vars for parallel script execution
currentSeq=""; numRunning=0

# Start the loop through the build options
for buildLine in ${build_list}; do

    # Extract the info we required"
    seq=`echo ${buildLine} | cut -d"," -f1`
    build=`echo ${buildLine} | cut -d"," -f2-`
    buildlogpath=`echo ${build} | sed "s/tf-params/logs/g"`
    mkdir -p ${buildlogpath}

    # We need to check if this is a new sequence, or a repeated one
    if [ "${seq}" = "${currentSeq}" ]; then
        # Repeated sequence
        runCheck=${scParallel}
    else
        # New sequence
        runCheck=1
    fi

    # How many tf-run.sh are currently running? If ${runCheck} or more, pause!
    wait_for_slot tf-run.sh ${runCheck}

    # Store the sequence we are about to start for future reference
    currentSeq=${seq}

    ##################################################################
    # Validate that we are allowed to perform an action on this target
    chkPrevent=`is_prevented ${build}`
    chkProtect=`is_protected ${build}`
    # Is this build prevented from running
    if [ "${chkPrevent}" = "Y" ]; then
        log_message "NOT executing resource ${seq} - ${build} (prevent ON)" warning
        continue
    fi
    # Is this build protected from destruction
    if [ "${chkProtect}" = "Y"  -a "${action}" = "destroy" ]; then
        log_message "    - skipping ${build} (protected)" warning
        continue
    fi

    ##################################################################

    log_message "    executing resource ${seq} - ${build}" notice
    if [ "Y" = ${verbose} ]; then
        ./tf-run.sh ${opts} ${action} ${build} 

        ret=$?
        if [ ${ret} -ne 0 ]; then
            log_message "        - ${action} failed :(" err
        else
            log_message "        - ${action} success!" notice
        fi
    else
        # Write regular messages to the log file, allow stderr to fall out of script
        ./tf-run.sh ${opts} ${action} ${build} > ${buildlogpath}/build.log &
    fi

done

# Wait for all scripts to complete
wait_for_slot tf-run.sh 1

log_message "Build complete!                 "

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
