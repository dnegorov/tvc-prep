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
dnf install tionix-tvc-broker tionix-tvc-control -y
echo

# Ставим NetworkManager-tui
echo "Install NetworkManager-tui:"
dnf NetworkManager-tui -y
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

echo "####################################################"
echo "#                                                  #"
echo "#  STAGE 1: COMPLETE                               #"
echo "#                                                  #"
echo "####################################################"

echo "####################################################"
echo "#                                                  #"
echo "#  CHECK AND CHANGE NETWORK INTERFACE              #"
echo "#                                                  #"
echo "####################################################"