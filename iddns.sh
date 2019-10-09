#!/bin/env bash

#
# Infomaniak Dynamic DNS Client
#
# Author: Nicolas Hedger <nicolas@hedger.ch>
# Version: 1.0.0
# License: MIT
#

# Set default values
IDDNS_USERNAME=""
IDDNS_PASSWORD=""
IDDNS_GRABBER="https://api.ipify.org/"
IDDNS_IP=""
IDDNS_TIMESTAMPS=false
IDDNS_SILENT=false

function usage()
{
    echo ""
    echo "[k] Infomaniak Dynamic DNS Client"
    echo ""

    if [[ ! -z "$1" ]]; then
		echo "ERROR: $1"
		echo ""
	  fi

    echo "Usage: iddns -u <username> -p <password> [-i <ip>] [-g <grabber>] [-t] [-s] HOSTNAME"
    echo "Usage: iddns -c <config> [-u <username>] [-p <password>] [-i <ip>] [-g <grabber>] [-t] [-s] HOSTNAME"
    echo ""
    echo "Notes:"
    echo ""
    echo " * If the remote IP address is not specified, it is automatically obtained through https://www.ipify.org/"
    echo ""
}

# Helper function for logging messages with the date and time
function log()
{
    if [[ ${IDDNS_SILENT} = false ]]; then
        if [[ ${IDDNS_TIMESTAMPS} = true ]]; then
            echo "$(date -u) : $1"
        else
            echo $1
        fi
    fi
}

# Grab arguments from command line
while getopts ":c:u:p:i:g:ts" opt
do
    case ${opt} in
        c)
            # Ensure that the config.example file exists
            if [[ ! -f $OPTARG ]]; then
                usage "The provided configuration file is invalid: ${OPTARG}"
            fi
            opt_config=${OPTARG}
            ;;
        u)
            opt_username=${OPTARG}
            ;;
        p)
            opt_password=${OPTARG}
            ;;
        i)
            opt_ip=${OPTARG}
            ;;
        g)
            opt_grabber=${OPTARG}
            ;;
        t)
            opt_timestamps=true
            ;;
        s)
            opt_silent=true
            ;;
        \?)
            usage "Invalid argument"
            ;;
    esac
done
shift $((OPTIND - 1))

# Grab the hostname from the arguments list
IDDNS_HOSTNAME=$1

# Import values from configuration file if provided
if [[ -f ${opt_config} ]]; then
    source ${opt_config}
fi

# Override configuration values with the ones provided as arguments
if [[ ${opt_username} ]]; then
    IDDNS_USERNAME=${opt_username}
fi

if [[ ${opt_password} ]]; then
    IDDNS_PASSWORD=${opt_password}
fi

if [[ ${opt_ip} ]]; then
    IDDNS_IP=${opt_ip}
fi

if [[ ${opt_grabber} ]]; then
    IDDNS_GRABBER=${opt_grabber}
fi

if [[ ${opt_timestamps} ]]; then
    IDDNS_TIMESTAMPS=${opt_timestamps}
fi

if [[ ${opt_silent} ]]; then
    IDDNS_SILENT=${opt_silent}
fi

# If any required arguments is missing, show usage
if [ "${IDDNS_USERNAME}" = "" ] || [ "${IDDNS_PASSWORD}" = "" ] || [ "${IDDNS_HOSTNAME}" = "" ]; then
    usage
    exit 0
fi

# If no IP was specified, try to grab one automatically
if [[ ${IDDNS_IP} = "" ]]; then

    log "Grabbing your current public IP from ${IDDNS_GRABBER}"

    IDDNS_IP=$(curl --silent "${IDDNS_GRABBER}")

    # If CURL fails to grab the IP for some reason, exit
    if [[ -z $? ]]; then
        log "Could not grab your current public IP from ${IDDNS_GRABBER}. Try setting it manually."
        exit 1
    fi

    log "Your public IP address is ${IDDNS_IP}"
fi

# Try to update the record
log "Trying to make ${IDDNS_HOSTNAME} point to ${IDDNS_IP}"
OUTPUT=$(curl --silent --user "${IDDNS_USERNAME}:${IDDNS_PASSWORD}" \
"https://infomaniak.com/nic/update?hostname=${IDDNS_HOSTNAME}&myip=${IDDNS_IP}")

# Parse output to determine outcome
case ${OUTPUT} in
    "good ${IDDNS_IP}")
        # Everything went according to plan
        log "${IDDNS_HOSTNAME} now points to ${IDDNS_IP}"
        exit 0
        ;;
    "nochg ${IDDNS_IP}")
        # The record was already set to this IP
        log "${IDDNS_HOSTNAME} already points to ${IDDNS_IP}"
        exit 0
        ;;
    "nohost")
        # The hostname does not exist or has not been set as dynamic
        log "${IDDNS_HOSTNAME} is invalid or has not been set as dynamic"
        exit 1
        ;;
    "notfqdn")
        # The hostname is invalid
        log "${IDDNS_HOSTNAME} is not a valid FQDN"
        exit 1
        ;;
    "badauth")
        # Invalid credentials
        log "The provided credentials are invalid"
        exit 1
        ;;
    "conflict A")
        # IPv4 conflict
        log "Cannot add an A record because an AAAA record already exists for ${IDDNS_HOSTNAME}"
        exit 1
        ;;
    "conflict AAAA")
        # IPv6 conflict
        log "Cannot add an AAAA record because an A record already exists for ${IDDNS_HOSTNAME}"
        exit 1
        ;;
    "The Target field's structure for a A-type entry is incorrect.")
        # IP address invalid
        log "The provided IP address is invalid"
        exit 1
        ;;
    *)
        log "${OUTPUT}"
        exit 1;
        ;;
esac
