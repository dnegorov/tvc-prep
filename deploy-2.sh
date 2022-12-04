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

# Запускаем сервисы
echo "Start BROKER"
systemctl enable --now tionix-tvc-broker || (echo "Start BROKER failed"; exit 1)
echo

echo "Start CONTROL"
systemctl enable --now tionix-tvc-control  || (echo "Start CONTROL failed"; exit 1)
echo

# Ждем ответа WEB-Interface
echo "Wait for WEB-Interface"
sleep 10
echo

# Активируем админа
echo "Create ADMIN user"
echo "result: " $(AppInit)
echo

# Получаем REALM_ID (корень СУ)
echo
REALM_ID=$(GetMasterRealmID)
echo "Realm_ID:   ""$REALM_ID"
echo


