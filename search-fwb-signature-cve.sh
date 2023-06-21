#!/bin/bash

# This script performs a search for any set of keywords within signatures, utilizing the FortiWeb API.
# Ensure curl and jq are installed on your system, as they are dependencies for this script.
# Modify the variables and list within the script to suit your search criteria and your environment.
# The list isn't limited to CVEs; it can include any keywords of your interest.

# bbuonassera June 2023

########################################################################################################
# Adjust the Variables                                                                                 #
########################################################################################################

# Signature Policy Name
mkey="Extended%20Protection"

# FortiWeb IP
HOST=192.168.4.2

# Admin Authentication
TOKEN=`echo '{"username":"userapi","password":"abc123","vdom":"root"}' | base64`

# List of CVEs
cves=(
"CVE-2022-42004" "CVE-2022-42003" "CVE-2021-20190" "CVE-2020-9548"
"CVE-2020-9547" "CVE-2020-9546" "CVE-2020-8840" "CVE-2020-36518"
"CVE-2020-36189" "CVE-2020-36188" "CVE-2020-36187" "CVE-2020-36186"
"CVE-2020-36185" "CVE-2020-36184" "CVE-2020-36183" "CVE-2020-36182"
"CVE-2020-36181" "CVE-2020-36180" "CVE-2020-36179" "CVE-2020-35491"
"CVE-2020-35490" "CVE-2020-25649" "CVE-2020-24750" "CVE-2020-24616"
"CVE-2020-14195" "CVE-2020-14062" "CVE-2020-14061" "CVE-2020-14060"
"CVE-2020-11620" "CVE-2020-11619" "CVE-2020-11113" "CVE-2020-11112"
"CVE-2020-11111" "CVE-2020-10969" "CVE-2020-10968" "CVE-2020-10673"
"CVE-2020-10672" "CVE-2020-10650" "CVE-2019-20330" "CVE-2019-17531"
"CVE-2019-17267" "CVE-2019-16943" "CVE-2019-16942" "CVE-2019-16335"
"CVE-2019-14893" "CVE-2019-14892" "CVE-2019-14540" "CVE-2019-14439"
"CVE-2019-14379" "CVE-2019-12814" "CVE-2019-12384"
)

########################################################################################################
# Script                                                                                 #
########################################################################################################

# Prepare URL and Headers
base_url="https://${HOST}/api/v2.0/waf/signature.descsearch?mkey=${mkey}&description="
authorization_header="Authorization: ${TOKEN}"
accept_header="Accept: application/json"

for cve in ${cves[@]}
do
  # Execute the curl command and save the HTTP status code
  results=$(curl --insecure --silent --request GET "${base_url}${cve}" \
  --header "${authorization_header}" \
  --header "${accept_header}")

  # Check if the results are valid JSON
  if ! jq empty <<<"$results" 2>/dev/null; then
    echo "Error: Invalid response for $cve"
    continue
  fi

  # Check if the CVE is found in the description
  if echo $results | jq '.results[].desc' | grep -q $cve; then
    echo "$cve has been found in"
        echo ""
    count=$(echo "$results" | jq '.results | length')
    for (( i=0; i<$count; i++ )); do
      id=$(echo "$results" | jq -r ".results[$i].id")
      desc=$(echo "$results" | jq -r ".results[$i].desc")
      echo -e "\tsignature id: $id"
      echo -e "\tsignature description: $desc"
      echo ""
    done
  else
    echo "$cve was not found"
  fi
done
