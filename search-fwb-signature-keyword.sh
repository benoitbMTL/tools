#!/bin/bash

# This script performs a keyword search within signatures using the FortiWeb API.
# Ensure that curl and jq are installed on your system as they are required for this script.
# Please adjust the variables (Username, Password, VDOM, Signature Policy Name and FortiWeb IP)
# within the script to match your specific search criteria and environment.

# bbuonassera June 2023

# Usage: ./search-fwb-signature-keyword.sh [OPTION] "<keyword>"
# Options:
#   -p, --print:   Print search results (default)
#   -c, --count:   Print count of search results
#   -i, --id:      Filter by specific ID(s) (can be specified multiple times)
#   -h, --help:    Display help
#   "<keyword>": Keyword for the search.
# 
# Examples:
#   ./search-fwb-signature-keyword.sh "Log4j" -p                # print all signatures with description containing keyword "Log4j"
#   ./search-fwb-signature-keyword.sh "Log4j" -c                # count all signatures with description containing keyword "Log4j"
#   ./search-fwb-signature-keyword.sh "CVE-2021-44228" -p       # print all signatures with specific CVE reference
#   ./search-fwb-signature-keyword.sh "CVE-2023" -c             # count all signatures with partial CVE reference
#   ./search-fwb-signature-keyword.sh "HTTP Response Body" -p   # print all signatures with description containing "HTTP Response Body"
#   ./search-fwb-signature-keyword.sh "Log4j" -i                # print all signatures id with keyword "Log4j"

########################################################################################################
# Adjust the Variables                                                                                 #
########################################################################################################

# FortiWeb IP
HOST=192.168.4.2

# Admin Authentication
TOKEN=`echo '{"username":"userapi","password":"abc123","vdom":"root"}' | base64`

# Signature Policy Name
mkey="Extended%20Protection"

########################################################################################################
# Script                                                                                 #
########################################################################################################

# Default mode
print_mode=true
count_mode=false
id_mode=false

# Print usage/help function
print_usage() {
    echo "Usage: $0 [OPTION] \"<keyword>\""
    echo "Options:"
    echo "  -p, --print:   Print search results (default)"
    echo "  -c, --count:   Print count of search results"
    echo "  -i, --id:      Filter by specific ID(s) (can be specified multiple times)"
    echo "  -h, --help:    Display help"
    echo "  \"<keyword>\": Keyword for the search."
    echo ""
    echo "Examples:"
    echo "  $0 \"Log4j\" -p                # print all signatures with description containing keyword \"Log4j\""
    echo "  $0 \"Log4j\" -c                # count all signatures with description containing keyword \"Log4j\""
    echo "  $0 \"CVE-2021-44228\" -p       # print all signatures with specific CVE reference"
    echo "  $0 \"CVE-2023\" -c             # count all signatures with partial CVE reference"
    echo "  $0 \"HTTP Response Body\" -p   # print all signatures with description containing \"HTTP Response Body\""
    echo "  $0 \"Log4j\" -i                # print all signatures id with keyword \"Log4j\""
}

# Check if keyword is provided
if [ "$#" -lt 1 ]; then
    print_usage
    exit 1
fi

# Get options
while [ "$#" -gt 0 ]; do
    case "$1" in
    -p|--print)
        print_mode=true
        shift
        ;;
    -c|--count)
        count_mode=true
        print_mode=false
        shift
        ;;
    -i|--id)
        id_mode=true
		print_mode=false
        shift
        ;;
    -h|--help)
        print_usage
        exit 0
        ;;
    --) # end argument parsing
        shift
        break
        ;;
    -*|--*=) # unsupported flags
        echo "Error: Unsupported flag $1" >&2
        exit 1
        ;;
    *) # preserve positional arguments
        PARAMS="$PARAMS $1"
        shift
        ;;
    esac
done

# set positional arguments in their proper place
eval set -- "$PARAMS"

# Search Keyword
keyword="$@"

# Prepare URL and Headers
url_encoded_keyword=$(echo "$keyword" | tr ' ' '+')
url="https://${HOST}/api/v2.0/waf/signature.descsearch?mkey=${mkey}&description=${url_encoded_keyword}"
authorization_header="Authorization: ${TOKEN}"
accept_header="Accept: application/json"

# Execute curl and process results
response=$(curl --insecure --silent --request GET "${url}" \
--header "${authorization_header}" \
--header "${accept_header}")

# Remove control characters, \"", \", \r, \n, and \
# Otherwise jq cannot parse the json result
clean_response=$(echo "$response" | sed 's/[[:cntrl:]]//g' | sed 's/\\\"\"//g; s/\\"//g; s/\\r//g; s/\n//g; s/\\//g')

# Print signature IDs
if [ "$id_mode" = true ]; then
    echo $clean_response | jq -r '.results[].id'
fi

# Print mosignatures in JSON format
if [ "$print_mode" = true ]; then
    echo $clean_response | jq
fi

# Print the number of signatures
if [ "$count_mode" = true ]; then
    count=$(echo $clean_response | jq '.results | length')
    echo "Count of search results for ${keyword}: ${count}"
fi
