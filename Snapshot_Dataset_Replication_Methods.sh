#!/bin/bash

## PLEASE CUSTOMIZE FOR YOUR ENVIRONMENT
## THIS SCRIPT IS FOR EXAMPLE PURPOSES ONLY
## THE TEGILE INTELLIFLASH API REFERENCE GUIDE IS AVAILABLE BY VISITING THE TEGILE CUSTOMER SUPPORT COMMUNITY

## EXAMPLE INCLUDES SNAPSHOT, DATASET AND REPLICATION METHODS

clear
echo -e '\n'
echo "Checking for jq for JSON procesing"
jq --version
if [ $? -ne 0 ] 
	then
	echo -e '\n';	
	echo "jq is missing";
	echo "jq is required for this script to function";
	echo -e '\n'
	echo "Commands to use yum to install jq:";
	echo -e '\n'
	echo "yum install epel"
	echo "yum install jq"
	echo -e '\n'
	exit 1
	else
	echo "jq is working";
fi
echo "Checking for curl"
curl --version
if [ $? -ne 0 ] 
	then
	echo -e '\n';	
	echo "curl is missing";
	echo "curl is required for this script to function";
	echo -e '\n'
	echo "Commands to use yum to install curl:";
	echo -e '\n'
	echo "yum install curl"
	echo -e '\n'
	exit 1
	else
	echo "curl is working";
fi

clear
echo -e '\n'
echo "This script will create a local snapshot of a project"
echo -e '\n'
echo "This script does not clean up old snapshots"
echo -e '\n'

## CLEAR VARIABLES FOR USE
unset auth_token
unset tegileuser
unset tegilepwd
unset mgmt
unset pool
unset project
unset ss_name
unset quiescent
unset lun
unset luid
unset lunsize
unset lunblocksize
unset tp
unset protocol
unset datasetpath
unset repguid

## SET USERNAME AND PASSWORD
zebiuser="admin"
zebipwd="yourpassword"
auth_token=$(echo -n "$zebiuser:$zebipwd" | openssl enc -base64)

## SET IntelliFlash FLOATING MGMT ADDRESS
mgmt="10.55.222.111"

## SET DATE TIME FOR SNAPSHOT NAME
ss_name=$(date +"%Y%m%d%H%M%S")

## PROJECT NAME
pool="pool1"
localpool="true"
project="CIFS"
app_consistent="false"
lun="LUNSnapTest"
recursiveDelete="true"

echo -e '\n'

## CREATE NEW PROJECT SNAPSHOT
curl -X POST -H "Authorization:Basic $auth_token" -H Content-Type:application/json -d '[{"poolName": "'$pool'", "name": "'$project'", "local": '$localpool'}, "'$ss_name'", '$app_consistent']' https://$mgmt/zebi/api/v2/createProjectSnapshot -k

## GET PROJECT SNAPSHOT CREATION STATUS
curl -X POST -H "Authorization:Basic $auth_token" -H Content-Type:application/json -d '["'$pool'", "'Manual-P-$ss_name'"]' https://$mgmt/zebi/api/v2/getProjectSnapshotCreationStatus -k

## GET LUN DETAILS
curl -X POST -H "Authorization:Basic $auth_token" -H Content-Type:application/json -d '["'$pool'", "'$project'", '$localpool']' https://$mgmt/zebi/api/v2/listVolumes -k

## CREATE NEW LUN SNAPSHOT
curl -X POST -H "Authorization:Basic $auth_token" -H Content-Type:application/json -d '[{"poolName": "'$pool'", "projectName": "'$project'", "name": "'$lun'", "luId": "YOUR_LUID_GOES_HERE", "volSize": "1073741824", "blockSize": "16KB", "thinProvision": true, "protocol": "iSCSI", "datasetPath": "pool1/Local/CIFS/LUNSnapTest", "local": '$localpool'}, "'$ss_name'", '$app_consistent']' https://$mgmt/zebi/api/v2/createVolumeSnapshot -k

## GET SNAPSHOT LIST
curl -X POST -H "Authorization:Basic $auth_token" -H Content-Type:application/json -d '["'$pool'/Local/'$project'/'$lun'",".*"]' https://$mgmt/zebi/api/v2/listSnapshots -k

sleep 5

## DELETE PROJECT SNAPSHOT
curl -X POST -H "Authorization:Basic $auth_token" -H Content-Type:application/json -d '["'$pool'/Local/'$project'@Manual-P-'$ss_name'", '$recursiveDelete']' https://$mgmt/zebi/api/v2/deleteProjectSnapshot -k

## DELETE LUN SNAPSHOT
curl -X POST -H "Authorization:Basic $auth_token" -H Content-Type:application/json -d '["'$pool'/Local/'$project'/'$lun'@Manual-V-'$ss_name'", '$recursiveDelete']' https://$mgmt/zebi/api/v2/deleteVolumeSnapshot -k

## GET PROJECT REPLICATION GUID
curl -X POST -H "Authorization:Basic $auth_token" -H Content-Type:application/json -d '["'$pool'","'$project'"]' https://$mgmt/zebi/api/v2/getReplicationConfigList -k
repquid=$(curl -X POST -H "Authorization:Basic $auth_token" -H Content-Type:application/json -d '["'$pool'","'$project'"]' https://$mgmt/zebi/api/v2/getReplicationConfigList -k)

## GET REPLICATION STATUS
curl -X POST -H "Authorization:Basic $auth_token" -H Content-Type:application/json -d $repquid https://$mgmt/zebi/api/v2/getReplicationStatus -k

## START REPLICATION
curl -X POST -H "Authorization:Basic $auth_token" -H Content-Type:application/json -d $repquid https://$mgmt/zebi/api/v2/startReplication -k

exit