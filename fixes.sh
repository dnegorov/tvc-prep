. params.conf
. functions.sh
. functions-api.sh

function FixesApplay () {
    for fix in ${!FIX_LIST[@]}
        do
            func=${FIX_LIST["$fix"]}
            echo "========================================="
            echo "Fix:  "$fix 
            echo "Func: "$func
            echo "-----------------------------------------"
            $func
            echo
            echo "========================================="
        done
}

# Disable selinux
function FixForDisableSELinux () {
    config_file="/etc/selinux/config"
    param_name="SELINUX"
    new_value="disabled"
    SetParamInConfig "$param_name" "$new_value" "$config_file"

    setsebool -P nfs_export_all_rw 1
    setenforce 0
}

# Can not create storage on local disk
function FixForLocalStorage () {
    mkdir -p /home/tvc/storages
    chown -R tvc:tvc /home/tvc/storages
}

# Change IF names from eth0 to enp4s0 format
function FixForNetworkInGrub () {
    config_file="/etc/default/grub"
    param_name="GRUB_CMDLINE_LINUX_DEFAULT"
    new_value='net.ifnames=1 quiet splash'
    SetParamInConfig "$param_name" '"'"$new_value"'"' "$config_file"
    grub2-mkconfig -o /boot/grub2/grub.cfg
}

# Disable auto creation for IF "Wired..."
function FixForNetworkManager () {
    config_file="/etc/NetworkManager/conf.d/enable-auto-eth.conf"
    param_name="no-auto-default"
    new_value="*"
    SetParamInConfig "$param_name" "$new_value" "$config_file"
}

# Force use ipv4 for java in broker service
function FixForBrokerServiceIPv4 () {
    BROKER_SERVICE_FILE="/usr/lib/systemd/system/tionix-tvc-broker.service"
    BROKER_SERVICE_PARAM="ExecStart"
    BROKER_SERVICE_ADDED_KEY="-Djava.net.preferIPv4Stack=true"
    current_value=$(GetParamValueFromConfig "$BROKER_SERVICE_PARAM" "$BROKER_SERVICE_FILE")
    new_value=$(StrReplace "$current_value" 'java -server' 'java -Djava.net.preferIPv4Stack=true -server')
    SetParamInConfig "$BROKER_SERVICE_PARAM" "$new_value" "$BROKER_SERVICE_FILE"
    systemctl daemon-reload
}




