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
echo " Realm:                   "$REALM
echo " DC name:                 "$DC_NAME
echo " DC-ID:                   "$DC_ID
echo " Cluster ID:              "$cluster_id
echo " Host ID:                 "$AGENT_NODE_ID
echo " tvcmgmt Net ID:          "$MGMNT_NET_ID
echo " tvcmgmt Profile ID:      "$mgmtnet_profile_id
echo " INTERCONNECT Net ID:     "$INTERCONNECT_ID
echo " INTERCONNECT Profile ID: "$interconnect_profile_id


echo
# СОЗДАЕМ ПРЕДЛОЖЕНИЕ РАЗВЕРТКИ: СЕТИ
echo "Create network proporsal: ""$PROPORSAL_NET_NAME"
echo " Create network deployment with managment network..."
NETWORK_DEPLOY=$(CreateNetDeploymentEntity "$PROPORSAL_NET_NAME" "true" "$MGMNT_NET_ID" "$DC_ID")
echo "==========================="
echo " NETWORK_DEPLOY:"
echo "$NETWORK_DEPLOY" | jq
echo "==========================="
echo " Add network to deployment: ""$SU_NET_INTERCONNECT_NAME"
NETWORK_DEPLOY=$(AddNetworkToNetDeploymentEntity "$NETWORK_DEPLOY" "1" "$INTERCONNECT_ID" "$DC_ID")
echo "==========================="
echo " NETWORK_DEPLOY:"
echo "$NETWORK_DEPLOY" | jq
echo "==========================="
echo " Applay network deployment..."
echo " result: "$(ApplayNetDeployment "$DC_ID" "$NETWORK_DEPLOY")
NETWORK_DEPLOYMENT_ID=$(GetNetworkDeploymentID "$PROPORSAL_NET_NAME" "$DC_ID")
echo " Network deployment ID: "$NETWORK_DEPLOYMENT_ID

echo
echo "Create compute proporsal: "$PROPORSAL_COMPUTE_NAME
COMPUTE_DEPLOY=$(CreateComputeDeploymentEntity "$PROPORSAL_COMPUTE_NAME" "1" "$PROPORSAL_COMPUTE_CPU_CORES_MAX" "1000" "$PROPORSAL_COMPUTE_CPU_SPEED_MAX" "1024" "$PROPORSAL_COMPUTE_RAM_MAX" "$PROPORSAL_COMPUTE_VRAM_MAX")
echo "==========================="
echo " COMPUTE_DEPLOY:"
echo "$COMPUTE_DEPLOY" | jq
echo "==========================="
echo
echo " Applay compute deployment..."
echo " result: "$(ApplayComputeDeployment "$DC_ID" "$COMPUTE_DEPLOY")
COMPUTE_DEPLOYMENT_ID=$(GetComputeDeploymentID "$PROPORSAL_COMPUTE_NAME" "$DC_ID")
echo " Compute deployment ID: "$COMPUTE_DEPLOYMENT_ID

LOCAL_STORAGE_ID=$(GetStorageId "$DC_ID" "$STOR_HDD_NAME")
ISO_STORAGE_ID=$(GetStorageId "$DC_ID" "$STOR_ISO_NAME")

echo
# СОЗДАЕМ ПРЕДЛОЖЕНИЕ РАЗВЕРТКИ: ХРАНИЛИЩА
echo "Create storage proporsal: ""$PROPORSAL_STOR_NAME"
echo " Create storage deployment with ""$STOR_HDD_NAME""..."
STORAGE_DEPLOY=$(CreateStorageDeploymentEntity "$PROPORSAL_STOR_NAME" "true" "$LOCAL_STORAGE_ID" "$PROPORSAL_STOR_HDD_SIZE" "$DC_ID")
echo "==========================="
echo " STORAGE_DEPLOY:"
echo "$STORAGE_DEPLOY" | jq
echo "==========================="
echo " Add storage to deployment: ""$STOR_ISO_NAME"
STORAGE_DEPLOY=$(AddStorageToStorDeploymentEntity "$STORAGE_DEPLOY" "1" "$ISO_STORAGE_ID" "$PROPORSAL_STOR_ISO_SIZE" "$DC_ID")
echo "==========================="
echo " STORAGE_DEPLOY:"
echo "$STORAGE_DEPLOY" | jq
echo "==========================="
echo " Applay storage deployment..."
echo " result: "$(ApplayStorageDeployment "$DC_ID" "$STORAGE_DEPLOY")
STORAGE_DEPLOYMENT_ID=$(GetStorageDeploymentID "$PROPORSAL_STOR_NAME" "$DC_ID")
echo " Storage deployment ID: "$STORAGE_DEPLOYMENT_ID

echo
echo
echo " Network deployment ID: ""$NETWORK_DEPLOYMENT_ID"
echo " Compute deployment ID: ""$COMPUTE_DEPLOYMENT_ID"
echo " Storage deployment ID: ""$STORAGE_DEPLOYMENT_ID"

echo
# СОЗДАЕМ ВИРТУАЛЬНЫЙ ДЦ
echo "Create Virtual DC: ""$VIRTUAL_DC_NAME"
VIRTUAL_DC=$(CreateVirtualDCEntity "$VIRTUAL_DC_NAME" "true")
echo " Add compute deployment: ""$COMPUTE_DEPLOYMENT_ID"
VIRTUAL_DC=$(AddDeploymentToVirtualDCEntity "$VIRTUAL_DC" "0" "COMPUTE" "$COMPUTE_DEPLOYMENT_ID")
echo " Add network deployment: ""$NETWORK_DEPLOYMENT_ID"
VIRTUAL_DC=$(AddDeploymentToVirtualDCEntity "$VIRTUAL_DC" "1" "NETWORK" "$NETWORK_DEPLOYMENT_ID")
echo " Add storage deployment: ""$STORAGE_DEPLOYMENT_ID"
VIRTUAL_DC=$(AddDeploymentToVirtualDCEntity "$VIRTUAL_DC" "2" "STORAGE" "$STORAGE_DEPLOYMENT_ID")
echo "==========================="
echo " VIRTUAL_DC:"
echo "$VIRTUAL_DC" | jq
echo "==========================="
echo " Applay Virtual DC..."
echo " result: "$(CreateVirtualDC "$DC_ID" "$VIRTUAL_DC")
VIRTUAL_DC_ID=$(GetVirtualDCID "$VIRTUAL_DC_NAME" "$DC_ID")
echo " Virtual DC ID: "$VIRTUAL_DC_ID

echo
echo
REALM_ID=$(GetMasterRealmID)
echo "Realm_ID:           "$REALM_ID
echo

echo
# СОЗДАЕМ ПРОЕКТ В НАШ ВИРТУАЛЬНЫЙ ДЦ
echo "Create Project: ""$PROJECT_NAME"
PROJECT=$(CreateProjectEntity "$PROJECT_NAME" "true" "$VIRTUAL_DC_ID" "$REALM_ID")
echo " Add compute deployment: ""$COMPUTE_DEPLOYMENT_ID"
PROJECT=$(AddDeploymentToProjectEntity "$PROJECT" "0" "COMPUTE" "$COMPUTE_DEPLOYMENT_ID")
echo " Add network deployment: ""$NETWORK_DEPLOYMENT_ID"
PROJECT=$(AddDeploymentToProjectEntity "$PROJECT" "1" "NETWORK" "$NETWORK_DEPLOYMENT_ID")
echo " Add storage deployment: ""$STORAGE_DEPLOYMENT_ID"
PROJECT=$(AddDeploymentToProjectEntity "$PROJECT" "2" "STORAGE" "$STORAGE_DEPLOYMENT_ID")
echo "==========================="
echo " PROJECT:"
echo "$PROJECT" | jq
echo "==========================="
echo " Applay Project..."
echo " result: "$(CreateProject "$VIRTUAL_DC_ID" "$PROJECT")
PROJECT_ID=$(GetProjectID "$PROJECT_NAME" "$VIRTUAL_DC_ID")
echo " Project ID: "$PROJECT_ID

