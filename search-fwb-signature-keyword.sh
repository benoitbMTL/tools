# This script performs a keyword search within signatures using the FortiWeb API.
# Ensure that curl and jq are installed on your system as they are required for this script.
# Please adjust the variables within the script to match your specific search criteria and environment.

# bbuonassera June 2023

#!/bin/bash

# Signature Policy Name
mkey="DVWA_SIGNATURE_PROFILE"

# Search Keyword
description="CVE-2022-1357"

# FortiWeb IP
HOST=192.168.4.2

# Admin Authentication
TOKEN=`echo '{"username":"userapi","password":"abc123","vdom":"root"}' | base64`

# Prepare URL and Headers
url="https://${HOST}/api/v2.0/waf/signature.descsearch?mkey=${mkey}&description=${description}"
authorization_header="Authorization: ${TOKEN}"
accept_header="Accept: application/json"

# Execute curl
echo "Search result for ${description}:"
echo ""
curl --insecure --silent --request GET "${url}" \
--header "${authorization_header}" \
--header "${accept_header}" | jq
