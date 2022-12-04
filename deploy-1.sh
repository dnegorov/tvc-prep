#!/bin/bash

. params.conf
. functions.sh
. functions-api.sh
. fixes.sh


echo "####################################################"
echo "#                                                  #"
echo "#  STAGE 1: Prepare host                           #"
echo "#                                                  #"
echo "####################################################"

echo
echo

# Обновляемся
echo "Updates:"
dnf update -y
echo

# Ставим Систему Управления
echo "Install Managment System:"
dnf -y install tionix-tvc-broker tionix-tvc-control
echo

# Ставим NetworkManager-tui
echo "Install NetworkManager-tui:"
dnf -y install NetworkManager-tui
echo

# Ставим вспомогательные пакеты для работы скриптов
echo "Install curl and jq:"
dnf -y install curl jq
echo

# Задаем HOSTNAME
echo "Set hostname: "$HOST_NAME
hostnamectl set-hostname $HOST_NAME
echo

# Применяем фиксы по списку FIX_LIST из главного конфига
# Порядок применения фиксов не гарантируется!
FixesApplay FIX_LIST
echo

# Делаем диск под хранилще
PrepareStorageDisk $HOST_DISK_FOR_STORAGE $STOR_PATH
echo

# Делаем директории хранилища ISO + HDD
PrepareStorageDirs $STOR_PATH $STOR_DIR_ISO $STOR_DIR_HDD
echo

# Делаем NFS шары и включаем NFS server
NFSAddShare "$STOR_PATH"/"$STOR_DIR_ISO" $NFS_SHARE_PARAM_FOR_EXPORT
# NFSAddShare "$STOR_PATH"/"$STOR_DIR_HDD" $NFS_SHARE_PARAM_FOR_EXPORT
EnableNFS
echo

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
echo "####################################################"
echo "#                                                  #"
echo "#  STAGE 1: COMPLETE                               #"
echo "#                                                  #"
echo "####################################################"

echo "####################################################"
echo "#                                                  #"
echo -e "# \033[1;91mCHECK AND CHANGE NETWORK INTERFACE BEFORE REBOOT\033[0m #"
echo "#                                                  #"
echo "####################################################"