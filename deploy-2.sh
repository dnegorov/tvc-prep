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

echo "GET INFO ABOUT REALM: "$REALM
# Получаем REALM_ID (корень СУ)
echo
REALM_ID=$(GetMasterRealmID)
echo "           Realm_ID:   ""$REALM_ID"
echo

# Получаем MAC_POOL_ID (дефолтный)
echo
MAC_POOL_ID=$(GetMacPoolId 'По умолчанию')
echo " Default MAC pool ID: "$MAC_POOL_ID

echo
# СОЗДАЕМ НАШ НОВЫЙ ДЦ
echo "CREATE NEW DC:"
echo "  DC name:  "$DC_NAME
echo "  Local DC: "$USE_LOCAL_DC
echo $(CreateDC "$DC_NAME" "$DC_NAME" "$USE_LOCAL_DC" "$MAC_POOL_ID" "250")
echo
# ПОЛУЧАЕМ DC_ID НАШЕГО ДЦ
DC_ID=$(GetDCID "$DC_NAME")
echo "DC_ID: "$DC_ID

# СОХРАНЯЕМ DC_ID В КОНФИГ АГЕНТА
SetParamInConfig "agent.dc-id" "$DC_ID" "$AGENT_CONFIG_FILE"
# Сохраняем DC_ID в vcore-deploy.config
SetParamInConfig "agent.dc-id" "$DC_ID" "$COMMON_PARAMS_CONFIG_FILE"

# СТАРТУЕМ SANLOCK СЕРВИС
systemctl enable --now sanlock || (echo "Start SANLOCK failed"; exit 1)
echo "Wait SANLOC"
sleep 5
echo

# СТАРТУЕМ AGENT СЕРВИС
systemctl enable --now tionix-tvc-control  || (echo "Start AGENT failed"; exit 1)
echo "Wait AGENT"
sleep 5
echo





