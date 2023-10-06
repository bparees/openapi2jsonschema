#!/bin/sh

# $1 - directory containing json schema files
# $2 - optional, file containing formatted output of oc api-resources
# (will be retrieved from cluster if one is available)

# get openapi from cluser
# oc get --raw https://api.bparees.devcluster.openshift.com:6443/openapi/v2 > openapi.json

# get api-resources from cluster
# oc api-resources  | awk '{ print $(NF-2) " " $(NF) }' > /tmp/resources.txt

# convert openapi to json schema (run from dir containing just openapi.json)
# docker run -v .:/tmp/out quay.io/bparees/openapi2jsonschema:latest --stand-alone --expanded --kubernetes -p /tmp/out/openapi.json -o /tmp/out file:///tmp/out/openapi.json 



if [ -n "$2" ]; then
  echo "Using resource types from file $2"
  resources=$2
else
  echo "Fetching resource types from cluster"
  oc api-resources  | awk '{ print $(NF-2) " " $(NF) }' > /tmp/resources.txt
  resources=/tmp/resources.txt
fi

for file in "$1"/*; do
  if [ -f "$file" ]; then
    echo "Extracting gvk from json schema file: $file"
    gvk=$(echo $(jq -r .properties.apiVersion.enum[-1] $file) $(jq -r .properties.kind.enum[-1] $file) )
    echo "GVK is $gvk"
    grep -i "^$gvk\$" $resources
    if [ $? -ne 0 ]; then 
      echo "$gvk not found in $resources, $file does not represent a valid resource"
      rm $file
    fi
  fi
done


# list types in json schema files
# jq -r .properties.kind.enum[-1] * | sort > /tmp/schemaresources.txt
# list types in api-resources
# oc api-resources  | awk '{ print $(NF) }' | sort > /tmp/apiresources.txt

# compare to types in api-resources
# kdiff3 /tmp/schemaresources.txt /tmp/apiresources.txt
