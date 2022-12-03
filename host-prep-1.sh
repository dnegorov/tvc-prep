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

# Применяем фиксы по списку FIX_LIST из главного конфига
# Порядок применения фиксов не гарантируется!
FixesApplay FIX_LIST

# Делаем диск под хранилще
PrepareStorageDisk $HOST_DISK_FOR_STORAGE $STOR_PATH

# Делаем директории хранилища ISO + HDD
PrepareStorageDirs $STOR_PATH $STOR_DIR_ISO $STOR_DIR_HDD

# Делаем NFS шары и включаем NFS server
NFSAddShare "$STOR_PATH"/"$STOR_DIR_ISO" $NFS_SHARE_PARAM_FOR_EXPORT
# NFSAddShare "$STOR_PATH"/"$STOR_DIR_HDD" $NFS_SHARE_PARAM_FOR_EXPORT
EnableNFS


