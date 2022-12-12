#!/bin/bash

. params.conf
. functions.sh
. functions-api.sh
. fixes.sh

echo
echo "####################################################"
echo "#                                                  #"
echo "#  STAGE 2: Start Managment System                 #"
echo "#                                                  #"
echo "####################################################"
echo
echo

# Готовим сеть управления
# (удалит все соединения, создаст новое для сети управления)
FixForCreateNetwork

# Готовим конфиг для BROKER
SetParamListInConfig broker_config "$BROKER_CONFIG_FILE"
echo

# Готовим конфиг для CONTROL
SetParamListInConfig control_config "$CONTROL_CONFIG_FILE"
echo

# Готовим ПРЕДВАРИТЕЛЬНЫЙ конфиг для AGENT
SetParamListInConfig agent_config "$AGENT_CONFIG_FILE"
echo

# Готовим конфиг для SANLOCK
SetParamListInConfig sanlock_config "$SANLOCK_CONFIG_FILE"
echo

echo
# ЗАПУСКАЕМ СЕРВИСЫ
# BROKER всегда первый
echo "Start BROKER..."
systemctl enable --now tionix-tvc-broker || (echo "Start BROKER failed"; exit 1)
echo
echo "Wait BROKER 5 sec..."
sleep 5
# CONTROL вторым
echo "Start CONTROL..."
systemctl enable --now tionix-tvc-control  || (echo "Start CONTROL failed"; exit 1)
echo

# Ждем ответа WEB-Interface
echo "Wait for WEB-Interface 10 sec..."
sleep 10
echo

# АКТИВИРУЕМ АДМИНА
echo "Create ADMIN user..."
echo "result: " $(AppInit)
echo

# СОБИРАЕМ ДАННЫЕ ДЛЯ СОЗДАНИЯ СВОЕГО ДАТА ЦЕНТРА
echo "GET INFO ABOUT REALM: "$REALM
# Получаем REALM_ID (корень СУ)
REALM_ID=$(GetMasterRealmID)
echo " Realm_ID:            ""$REALM_ID"
# Получаем MAC_POOL_ID (дефолтный)
MAC_POOL_ID=$(GetMacPoolId 'По умолчанию')
echo " Default MAC pool ID: "$MAC_POOL_ID

echo
# СОЗДАЕМ НАШ НОВЫЙ ДЦ
echo "CREATE NEW DC..."
echo " DC name:  "$DC_NAME
echo " Local DC: "$USE_LOCAL_DC
echo " Result:   "$(CreateDC "$DC_NAME" "$DC_NAME" "$USE_LOCAL_DC" "$MAC_POOL_ID" "250")
# ПОЛУЧАЕМ DC_ID НАШЕГО ДЦ
DC_ID=$(GetDCID "$DC_NAME")
echo " DC_ID:    "$DC_ID
echo

# СОХРАНЯЕМ DC_ID В КОНФИГ АГЕНТА
SetParamInConfig "agent.dc-id" "$DC_ID" "$AGENT_CONFIG_FILE"
# Сохраняем DC_ID в vcore-deploy.config
SetParamInConfig "agent.dc-id" "$DC_ID" "$COMMON_PARAMS_CONFIG_FILE"

echo
# СТАРТУЕМ SANLOCK СЕРВИС
echo "Enable SANLOCK service..."
systemctl enable sanlock || (echo "Enable SANLOCK failed"; exit 1)
echo "Restart SANLOCK service..."
systemctl restart sanlock || (echo "Restart SANLOCK failed"; exit 1)
echo "Wait SANLOC 5 sec..."
sleep 5
echo

# СТАРТУЕМ AGENT СЕРВИС
echo "Enable AGENT service..."
systemctl enable tionix-tvc-agent || (echo "Enable AGENT failed"; exit 1)
echo "Restart AGENT service..."
systemctl restart tionix-tvc-agent || (echo "Restart AGENT failed"; exit 1)
echo "Wait AGENT 5 sec..."
sleep 5
echo

# ДОБАВЛЯЕМ НАШ УЗЕЛ В НАШ ДЦ
echo "Add host to cluster..."
# Получаем CLUSTER_ID дефолтного кластера в нашем ДЦ
CLUSTER_ID=$(GetClusterID 'Основной' "$DC_ID")
echo " Cluster ID:  "$CLUSTER_ID
# Добавляем узел в кластер
echo " Add host..."
echo " result:      "$(AddHostToCluster "$AGENT_NODE_ID" "$CLUSTER_ID" "$DC_ID")
echo " Wait host 5 sec..."
sleep 5
echo " Host status: "$(GetHostStatus "$AGENT_NODE_ID" "$DC_ID")
# Активируем узел
echo " Activate host.."
echo " result:      "$(ActivateHost "$AGENT_NODE_ID" "$DC_ID")
echo " Host status: "$(GetHostStatus "$AGENT_NODE_ID" "$DC_ID")

echo
# СОЗДАЕМ ЛОКАЛЬНУЮ ШАРУ ДЛЯ ВМ
echo "Create LOCAL storage for HDD..."
echo " result:     "$(CreateLocalStorage "$STOR_HDD_NAME" "true" "$STOR_PATH_HDD" "DATA" "$DC_ID" "$AGENT_NODE_ID")
LOCAL_STORAGE_ID=$(GetStorageId "$DC_ID" "$STOR_HDD_NAME")
echo " storage ID: "$LOCAL_STORAGE_ID
echo " wait 15 sec..."
sleep 15
echo " status: "$(GetStorageStatus "$LOCAL_STORAGE_ID" "$DC_ID")


# Делаем хост SPM (управляющим хранилищами) если он вдруг сам не сделался
#echo " Set host as SPM..."
#echo " result:     "$(SetHostSPM "$AGENT_NODE_ID" "$DC_ID")

echo
# СОЗДАЕМ NFS ШАРУ ДЛЯ ISO
echo "Create NFS share for ISO..."
echo " result:     "$(CreateNFSStorage "$DC_ID" "$AGENT_NODE_ID" "$STOR_ISO_NAME" "false" "$STOR_SRV_IP" "$STOR_PATH_ISO" "ISO")
ISO_STORAGE_ID=$(GetStorageId "$DC_ID" "$STOR_ISO_NAME")
echo " storage ID: "$ISO_STORAGE_ID
echo " wait 15 sec..."
sleep 15
echo " status: "$(GetStorageStatus "$ISO_STORAGE_ID" "$DC_ID")

echo
# СЕТЬ УПРАВЛЕНИЯ
# Правим сеть tvcmgmt, добавляем DNS если вдруг его там нет
echo "Add DNS to managment network..."
MGMNT_NET_ID=$(GetNetworkID 'tvcmgmt' "$DC_ID")
echo " tvcmgmt ID: ""$MGMNT_NET_ID"
MANAGMENT_NETWORK_PROPERTIES=$(GetNetwork "$MGMNT_NET_ID" "$DC_ID")
echo "==========================="
echo " MANAGMENT_NETWORK_PROPERTIES:"
echo "$MANAGMENT_NETWORK_PROPERTIES" | jq
echo "==========================="
echo
echo " Add DNS settings..."
MANAGMENT_NETWORK_PROPERTIES=$(SetNetworkParameter "$MANAGMENT_NETWORK_PROPERTIES" ".dnsServers" '["'"$HOST_DNS"'"]')
echo "==========================="
echo " MANAGMENT_NETWORK_PROPERTIES:"
echo "$MANAGMENT_NETWORK_PROPERTIES" | jq
echo "==========================="
echo
echo " Applay changes to network..."
echo "Result: "$(ChangeNetwork "$MGMNT_NET_ID" "$DC_ID" "$MANAGMENT_NETWORK_PROPERTIES")

echo
# СОЗДАЕМ СЕТЬ INTERCONNECT
echo "Create new network: "SU_NET_INTERCONNECT_NAME"..."
echo " Create Entity..."
INTERCONNECT_NETWORK_PROPERTIES=$(NetworkEntityTemplate)
echo " Change Name: ""$SU_NET_INTERCONNECT_NAME"
INTERCONNECT_NETWORK_PROPERTIES=$(SetNetworkParameter "$INTERCONNECT_NETWORK_PROPERTIES" ".networkName" '"'"$SU_NET_INTERCONNECT_NAME"'"')
INTERCONNECT_NETWORK_PROPERTIES=$(SetNetworkParameter "$INTERCONNECT_NETWORK_PROPERTIES" ".description" '"'"$SU_NET_INTERCONNECT_NAME"'"')
echo " Change VLAN: ""$SU_NET_INTERCONNECT_VLAN"
INTERCONNECT_NETWORK_PROPERTIES=$(SetNetworkParameter "$INTERCONNECT_NETWORK_PROPERTIES" ".vlanId" "$SU_NET_INTERCONNECT_VLAN")
echo " Change MTU:  ""$SU_NET_INTERCONNECT_MTU"
INTERCONNECT_NETWORK_PROPERTIES=$(SetNetworkParameter "$INTERCONNECT_NETWORK_PROPERTIES" ".mtu" "$SU_NET_INTERCONNECT_MTU")
echo "==========================="
echo " INTERCONNECT_NETWORK_PROPERTIES:"
echo "$INTERCONNECT_NETWORK_PROPERTIES" | jq
echo "==========================="
echo "result: "$(CreateNetwork "$DC_ID" "$INTERCONNECT_NETWORK_PROPERTIES")

echo
# ДОБАВЛЯЕМ СЕТЬ INTERCONNECT В НАШ КЛАСТЕР
echo " Get ""$SU_NET_INTERCONNECT_NAME"" ID..."
INTERCONNECT_ID=$(GetNetworkID "$SU_NET_INTERCONNECT_NAME" "$DC_ID")
echo " "$SU_NET_INTERCONNECT_NAME" ID: "$INTERCONNECT_ID
echo " Set network roles for cluster..."
IC_NET_CLUSTER_ROLES=$(SetClusterNetRoles "true" "false" "false" "false" "false" "false")
echo "==========================="
echo " IC_NET_CLUSTER_ROLES:"
echo "$IC_NET_CLUSTER_ROLES" | jq
echo "==========================="
echo " Add IC to cluster"
echo " result: "$(ApplyNetToCluster "$DC_ID" "$INTERCONNECT_ID" "$CLUSTER_ID" "$IC_NET_CLUSTER_ROLES")

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
# СОЗДАЕМ ПРЕДЛОЖЕНИЕ РАЗВЕРТКИ: ВЫЧИСЛИТЕЛЬНЫЕ РЕСУРСЫ
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


