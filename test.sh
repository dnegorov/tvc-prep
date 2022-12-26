#!/bin/bash

. params.conf
. functions.sh
. functions-api.sh
. fixes.sh


DC_ID=$(GetDCID "$DC_NAME")
cluster_id=$(GetClusterID 'Основной' "$DC_ID")
MGMNT_NET_ID=$(GetNetworkID 'tvcmgmt' "$DC_ID")
mgmtnet=$(GetNetwork "$MGMNT_NET_ID" "$DC_ID")
mgmtnet_profile_id=$(GetNetworkParameter "$mgmtnet" '.networkProfiles[0].id.id')

INTERCONNECT_ID=$(GetNetworkID "$SU_NET_INTERCONNECT_NAME" "$DC_ID")
interconnect=$(GetNetwork "$INTERCONNECT_ID" "$DC_ID")
interconnect_profile_id=$(GetNetworkParameter "$mgmtnet" '.networkProfiles[0].id.id')

echo
echo "DC Parameters"
echo " Realm:                    "$REALM
echo " DC name:                  "$DC_NAME
echo " DC-ID:                    "$DC_ID
echo " Cluster ID:               "$cluster_id
echo " Host ID:                  "$AGENT_NODE_ID
echo " tvcmgmt Net ID:           "$MGMNT_NET_ID
echo " tvcmgmt Profile ID:       "$mgmtnet_profile_id
echo " INTERCONNECT Net ID:      "$INTERCONNECT_ID
echo " INTERCONNECT Profile ID:  "$interconnect_profile_id

echo
echo "Deployment IDs:"

NETWORK_DEPLOYMENT_ID=$(GetNetworkDeploymentID "$PROPORSAL_NET_NAME" "$DC_ID")
echo "Network deployment ID:     "$NETWORK_DEPLOYMENT_ID


COMPUTE_DEPLOYMENT_ID=$(GetComputeDeploymentID "$PROPORSAL_COMPUTE_NAME" "$DC_ID")
echo "Compute deployment ID:     "$COMPUTE_DEPLOYMENT_ID

LOCAL_STORAGE_ID=$(GetStorageId  "$DC_ID" "$STOR_HDD_NAME")
echo "HDD Storage deployment ID: "$LOCAL_STORAGE_ID
ISO_STORAGE_ID=$(GetStorageId    "$DC_ID" "$STOR_ISO_NAME")
echo "ISO Storage deployment ID: "$ISO_STORAGE_ID

STORAGE_DEPLOYMENT_ID=$(GetStorageDeploymentID "$PROPORSAL_STOR_NAME" "$DC_ID")
echo "Storage deployment ID:     "$STORAGE_DEPLOYMENT_ID


VIRTUAL_DC_ID=$(GetVirtualDCID   "$VIRTUAL_DC_NAME" "$DC_ID")
echo "Virtual DC ID:             "$VIRTUAL_DC_ID

REALM_ID=$(GetMasterRealmID)
echo "Realm_ID:                  "$REALM_ID

PROJECT_ID=$(GetProjectID "$PROJECT_NAME" "$VIRTUAL_DC_ID")
echo "Project ID:                "$PROJECT_ID


vm1_hdd_0_name="vm1-hdd-0"
vm1_hdd_0_size_gb=20
vm1_hdd_0_size=$(( 1073741824 * $vm1_hdd_0_size_gb ))
echo
echo "Create HDD: ""$vm1_hdd_0_name"" Size: ""$vm1_hdd_0_size"
echo "result: "$(CreateHDD "$vm1_hdd_0_name" "$vm1_hdd_0_size" "$VIRTUAL_DC_ID" "$STORAGE_DEPLOYMENT_ID" "$LOCAL_STORAGE_ID")

