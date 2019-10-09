#!/bin/env bash

#
# Infomaniak Dynamic DNS Client
#
# Author: Nicolas Hedger <nicolas@hedger.ch>
# Version: 1.0.0
# License: MIT
#

function usage()
{
    echo ""
    echo "[k] Infomaniak Dynamic DNS Client"
    echo ""

    if [[ ! -z "$1" ]]; then
		echo "ERROR: $1"
		echo ""
	  fi

    echo "Usage: iddns -u <username> -p <password> [-i <ip>] [-g <grabber>] HOSTNAME"
    echo "Usage: iddns -c <config> [-u <username>] [-p <password>] [-i <ip>] [-g <grabber>] HOSTNAME"
    echo ""
    echo "Notes:"
    echo ""
    echo " * If the remote IP address is not specified, it is automatically obtained through https://www.ipify.org/"
    echo ""
}

# Grab arguments from command line
while getopts ":c:u:p:i:g:" opt
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
        \?)
            usage "Invalid argument"
            ;;
    esac
done
shift $((OPTIND - 1))

# Grab the hostname from the arguments list
IDDNS_HOSTNAME=$1

# Set default values
IDDNS_USERNAME=""
IDDNS_PASSWORD=""
IDDNS_GRABBER="https://api.ipify.org/"
IDDNS_IP=""

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

# If any required arguments is missing, show usage
if [ "${IDDNS_USERNAME}" = "" ] || [ "${IDDNS_PASSWORD}" = "" ] || [ "${IDDNS_HOSTNAME}" = "" ]; then
    usage
    exit 0
fi

# If no IP was specified, try to grab one automatically
if [[ ${IDDNS_IP} = "" ]]; then

    echo "Grabbing your current public IP from ${IDDNS_GRABBER}"

    IDDNS_IP=$(curl --silent "${IDDNS_GRABBER}")

    # If CURL fails to grab the IP for some reason, exit
    if [[ -z $? ]]; then
        echo "Could not grab your current public IP from ${IDDNS_GRABBER}. Try setting it manually."
        exit 1
    fi

    echo "Your public IP address is ${IDDNS_IP}"
fi

# Try to update the record
echo "Trying to make ${IDDNS_HOSTNAME} point to ${IDDNS_IP}"
OUTPUT=$(curl --silent --user "${IDDNS_USERNAME}:${IDDNS_PASSWORD}" \
"https://infomaniak.com/nic/update?hostname=${IDDNS_HOSTNAME}&myip=${IDDNS_IP}")

# Parse output to determine outcome
case ${OUTPUT} in
    "good ${IDDNS_IP}")
        # Everything went according to plan
        echo "${IDDNS_HOSTNAME} now points to ${IDDNS_IP}"
        exit 0
        ;;
    "nochg ${IDDNS_IP}")
        # The record was already set to this IP
        echo "${IDDNS_HOSTNAME} already points to ${IDDNS_IP}"
        exit 0
        ;;
    "nohost")
        # The hostname does not exist or has not been set as dynamic
        echo "${IDDNS_HOSTNAME} is invalid or has not been set as dynamic"
        exit 1
        ;;
    "notfqdn")
        # The hostname is invalid
        echo "${IDDNS_HOSTNAME} is not a valid FQDN"
        exit 1
        ;;
    "badauth")
        # Invalid credentials
        echo "The provided credentials are invalid"
        exit 1
        ;;
    "conflict A")
        # IPv4 conflict
        echo "Cannot add an A record because an AAAA record already exists for ${IDDNS_HOSTNAME}"
        exit 1
        ;;
    "conflict AAAA")
        # IPv6 conflict
        echo "Cannot add an AAAA record because an A record already exists for ${IDDNS_HOSTNAME}"
        exit 1
        ;;
    "The Target field's structure for a A-type entry is incorrect.")
        # IP address invalid
        echo "The provided IP address is invalid"
        exit 1
        ;;
    *)
        echo "${OUTPUT}"
        exit 1;
        ;;
esac
