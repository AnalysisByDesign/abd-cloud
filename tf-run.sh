#!/bin/bash
# --------------------------------------------------------------------------------
# Script name  : tf-run.sh
# Author       : Dave Rix (dave@analysisbydesign.co.uk)
# Created      : 2016-04-26
# Description  : This script execute terraform for a config path with options
# History      :
#  2016-04-26  : DAR - Initial script
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Variable Declaration and includes
# --------------------------------------------------------------------------------

scriptDesc="Terraform execution wrapper script"

# Include bash function library first
tmpPath=/tmp/terraform.$$
basePath=`git rev-parse --show-toplevel`
funcPath="${basePath}/funcs"
logPath="${basePath}/logs"
logfile=${logPath}/build.log

source ${funcPath}/bash_funcs.sh

mkdir -p ${logPath} ${tmpPath}

# Set some defaults
[[ "${verbose}" = "" ]] && verbose="N"
[[ "${v_verbose}" = "" ]] && v_verbose="N"
dryRun="N"      # Do we want to perform the actions
parallelism=10  # How many parallel terraform threads to run
override="N"
cleanCache="N"
statefileBucket="abd-tf-state"
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Local functions
# --------------------------------------------------------------------------------
function script_usage() {

         cat << EOF

Usage: 
        $0 [ OPTIONS ]  action  build_path

Options:
        -h                Show this message
        -c                Clean Terraform cache
        -d                Dry-run
        -t n              Max Terraform threads in parallel
        -o                Override 'protect' flag
        -v                Verbose output
        -vv               Very verbose output

Example:
        $0       plan    tf-params
        $0 -v -d apply   tf-params/account
        $0 -vvd  destroy tf-params/account/vpc

EOF

        # If we have called the usage statement, then something has gone wrong
        # so we can remove the lock file ready for the next run!
        script_cleanup 1
}

# The exit_script function will be used to catch unwanted exits of the script
# and to perform any cleanups
function script_exit() {
        log_message "Exiting ${scriptDesc} due to early termination..." err
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
while getopts ":vcdot:" OPTION
do
        case $OPTION in
                c)
                        cleanCache="Y"
                        ;;
                d)
                        dryRun="Y"
                        ;;
                t)
                        parallelism=${OPTARG}
                        ;;
                o)
                        override="Y"
                        ;;
                v)
                        [ "Y" = "${verbose}" ] && v_verbose="Y"
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
options="init|fmt|graph|refresh|show|taint|plan|apply|destroy|upload-state"
chk=`echo ${action} | egrep ${options}`
if [ "" = "${chk}" ]; then
    log_message "No valid action supplied." err
    script_cleanup 1
fi

# Strip a trailing "/" if supplied
target=`echo ${target} | sed "s/\/$//"`

# Extract the base param path from that supplied
paramPath=`getParamPath ${target}`
sequenceFiles="${paramPath}/sequence/*.csv"

# And validate the target
chkPrevent=`is_prevented ${target}`
chkProtect=`is_protected ${target}`
if [ "${chkPrevent}" = "Y" ]; then
    log_message "    - skipping ${target} (prevented)" err
    script_cleanup 0
fi
if [ "${chkProtect}" = "Y"  -a "${action}" = "destroy" -a "${override}" != "Y" ]; then
    log_message "    - skipping ${target} (protected)" err
    script_cleanup 0
fi

# Validate the passed in environment
config_scripts=`ls -1 ${target}/*_config.sh`
if [ "" = "${config_scripts}" ]; then
    log_message "No valid target environment supplied (${target})." err
    script_cleanup 1
fi

# Validate the environment access key
if [ "${AWS_DEFAULT_REGION}" = "" ]; then
    log_message "You have not prepared your environment for AWS." err
    script_cleanup 1
fi
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# We are ready to start, so check and set the lock file
log_message "Starting ${scriptName} for ${target}..."
obtain_lock
log_verbose "Verbose logging   = ${verbose}"
log_verbose "V-verbose logging = ${v_verbose}"
log_verbose "Dry-run           = ${dryRun}"
log_verbose "Lock file         = ${lockFile}"
log_verbose "Param path        = ${paramPath}"
log_verbose "Sequence file     = ${sequenceFiles}"
# --------------------------------------------------------------------------------

opts=""
build_resources=""
[ "${action}" = "destroy" ] && opts="-force"
[ "${action}" = "apply"   ] && opts="-auto-approve"

# -----------------------------------------------------------------------------
# Prepare the environment ready for execution
# -----------------------------------------------------------------------------
cd "${basePath}"/
tfvars=""
source ${paramPath}/global_config.sh

for cf_path in `echo ${target} | sed "s/\// /g"`; do
    # Move one path deeper
    cd ${cf_path}

    # Locate and run all environment config files
    for cf_file in `ls -1 *_config.sh 2>/dev/null`; do
        source ./${cf_file}
    done
    # Add any found tfvars files to the cli options
    for tf_file in `ls -1 *.tfvars 2>/dev/null`; do
        tfvars="${tfvars} -var-file=`pwd`/${tf_file}"
    done
done

# -----------------------------------------------------------------------------
# Finish setting up the TF specific options
# -----------------------------------------------------------------------------

opts="${opts} -lock=${lock} -lock-timeout=${locktimeout} -parallelism=${parallelism}"

# And use a dedicated folder for this script run, which we will clean up at the end.
export TF_DATA_DIR="${basePath}/${target}/.terraform"

# Pass some of the variables through to Terraform
export TF_VAR_acct_target="${acct_target}"
export TF_VAR_acct_billing="${acct_billing}"
export TF_VAR_acct_apex="${acct_apex}"
export TF_VAR_acct_auth="${acct_auth}"

export TF_VAR_account_name=`get_account_name ${acct_target}`
if [ "${TF_VAR_account_name}" = "" ]; then
    log_message "There is no description for account ${acct_target} - unable to continue." err
    script_cleanup 1
fi

# -----------------------------------------------------------------------------
# Prepare the Terraform variables and resource requirements
# -----------------------------------------------------------------------------
log_message "Preparing the infrastructure using ${target}"

[ "Y" = ${verbose} ] && terraform version
statefile="${TF_VAR_account_name}/${statefile_basename}.tfstate"

# -----------------------------------------------------------------------------
# Run terraform init for the required build_resources
# -----------------------------------------------------------------------------
log_verbose "Running Terraform for ${build_resources}"
log_verbose "    - storing state in ${statefileBucket}:${statefile}"
log_verbose "    - storing workspace in ${TF_DATA_DIR}"

retError=0
for resource in ${build_resources}; do

    # Now prepare the run the required code
    if [ "here" = "${resource}" ]; then
        cd "${basePath}/${target}"
    else
        cd "${templatePath}/${resource}"
    fi

    # Update all required modules
    if [ "Y" = ${cleanCache} ]; then
        log_verbose "    - clear down Terraform cache"
        if [ "Y" = ${dryRun} ]; then
            log_message "rm -rf ${basePath}/${target}/.terraform"
        else
            rm -rf ${basePath}/${target}/.terraform 2>/dev/null
        fi
    fi

#    # Update all required modules
#    log_verbose "    - updating modules"
#    if [ "Y" = ${dryRun} ]; then
#        log_message "terraform get -update=true"
#    else
#        if [ "Y" = ${verbose} ]; then
#            terraform get -update=true
#        else
#            terraform get -update=true > /dev/null
#        fi
#    fi

    # We always run an init command
    log_verbose "    - preparing backend store"
    if [ "Y" = ${dryRun} ]; then
        log_message "terraform terraform init -lock=${lock} 
            -backend-config=\"bucket=${statefileBucket}\" 
            -backend-config=\"key=${statefile}\""
    else
        if [ "Y" = ${verbose} ]; then
            terraform init -lock=${lock} \
                -backend-config="bucket=${statefileBucket}" \
                -backend-config="key=${statefile}"
        else
            terraform init -lock=${lock} \
                -backend-config="bucket=${statefileBucket}" \
                -backend-config="key=${statefile}" > /dev/null
        fi
    fi

    if [ $? -ne 0 ]; then
        log_message "An error has occurred during the Terraform init" err
        script_cleanup 1
    fi

    # And then optionally, we also run what has been requested
    if [ "${action}" != "init" ]; then
        log_verbose "    - running terraform ${action}"

        if [ "${action}" = "upload-state" ]; then
            log_message "Uploading terraform state file"
            cmd_params="state push errored.tfstate"
        elif [ "${action}" = "show" ]; then
            cmd_params="${action}"
        else
            cmd_params="${action} ${opts} ${tfvars}"
        fi

        [ "Y" = ${v_verbose} ] && export TF_LOG=INFO

        if [ "Y" = ${dryRun} ]; then
            log_message "terraform ${cmd_params}"
            ret=0
        else
            terraform ${cmd_params}
            ret=$?
        fi

        # If all went well, remove the statefile backup
        if [ ${ret} -eq 0 ]; then
            log_message "    - success running ${action} against ${target}" notice
            rm terraform.tfstate.backup 2>/dev/null
        else
            echo "    ^^^ - error running ${action} against ${target}" > /dev/stderr
            log_message "    - error running ${action} against ${target}" err
            retError=${ret}
            break
        fi

    fi

    echo ""

done

cd "${basePath}"

# --------------------------------------------------------------------------------
# Logging, analysis, email output, etc.
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# All done, so tidy stuff up a bit before exiting...
script_cleanup ${retError}
# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------
#      SCRIPT END
# --------------------------------------------------------------------------------
# --------------------------------------------------------------------------------
