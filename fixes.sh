. params.conf
. functions.sh
. functions-api.sh

# Run fixes from list
# Usage:
# FixesApplay LIST_OF_FIXES
#
# WARNING !!!
# ORDER IN LIST NOT FIXED
function FixesApplay () {
    local -n list=$1
    echo ${FUNCNAME[0]}":"
    for fix in ${!list[@]}
        do
            func=${list["$fix"]}
            echo "========================================="
            echo "Fix:  "$fix 
            echo "Func: "$func
            echo "-----------------------------------------"
            $func
            echo
            echo
        done
}

# Disable start GUI in ssh session
function FixForDisableGUI () {
    local file_path="/root/.bashrc"
    echo ${FUNCNAME[0]}":"
    # comment lines if ... fi where used variable XSRUNNING
    echo "Comment starting GUI in "$file_path
    sed -i '/XSRUNN/,/fi$/s/^/\#&/' "$file_path"
    sed -i 's/^\#\#/\#/g' "$file_path"
    
    local notification=$(echo 'echo -e "\n\033[1;91mRun TVC GUI with command: tvc-hyper-configurator\033[0m\n"')
    echo -e 'Add notification "'"\033[1;91mRun TVC GUI with command: tvc-hyper-configurator\033[0m"'" to '"$file_path"
    ApendFileUniqStr "$notification" "$file_path"
}

# Disable selinux
function FixForDisableSELinux () {
    local config_file="/etc/selinux/config"
    local param_name="SELINUX"
    local new_value="disabled"
    echo ${FUNCNAME[0]}":"
    SetParamInConfig "$param_name" "$new_value" "$config_file"
    echo "SELinux: nfs_export_all_rw"
    setsebool -P nfs_export_all_rw 1
    echo "SELinux: disable"
    setenforce 0
}

# Can not create storage on local disk
function FixForLocalStorage () {
    local tvc_dir="/home/tvc/storages"
    echo ${FUNCNAME[0]}":"
    echo "Create directory: "$tvc_dir
    mkdir -p "$tvc_dir"
    echo "Change owner: "$tvc_dir
    chown -R tvc:tvc "$tvc_dir"
}

# Change IF names from eth0 to enp4s0 format
function FixForNetworkInGrub () {
    local config_file="/etc/default/grub"
    local param_name="GRUB_CMDLINE_LINUX_DEFAULT"
    local new_value='net.ifnames=1 quiet splash'
    echo ${FUNCNAME[0]}":"
    SetParamInConfig "$param_name" '"'"$new_value"'"' "$config_file"
    echo "Applay GRUB changes: "
    grub2-mkconfig -o /boot/grub2/grub.cfg
}

# Disable auto creation for IF "Wired..."
function FixForNetworkManager () {
    local config_file="/etc/NetworkManager/conf.d/enable-auto-eth.conf"
    local param_name="no-auto-default"
    local new_value="*"
    echo ${FUNCNAME[0]}":"
    SetParamInConfig "$param_name" "$new_value" "$config_file"
}

# Force use ipv4 for java in broker service
function FixForBrokerServiceIPv4 () {
    local BROKER_SERVICE_FILE="/usr/lib/systemd/system/tionix-tvc-broker.service"
    local BROKER_SERVICE_PARAM="ExecStart"
    local BROKER_SERVICE_ADDED_KEY="-Djava.net.preferIPv4Stack=true"
    local current_value=$(GetParamValueFromConfig "$BROKER_SERVICE_PARAM" "$BROKER_SERVICE_FILE")
    local new_value=$(StrReplace "$current_value" 'java -server' 'java -Djava.net.preferIPv4Stack=true -server')
    echo ${FUNCNAME[0]}":"
    SetParamInConfig "$BROKER_SERVICE_PARAM" "$new_value" "$BROKER_SERVICE_FILE"
    systemctl daemon-reload
}

# Prepare MANAGMENT network interface
function FixForManagmentIF () {
    echo ${FUNCNAME[0]}":"
    local if_dir="/etc/NetworkManager/system-connections"
    echo "Remove all configs in: ""$if_dir"
    rm -rf "$if_dir""/*.nmconnection"
    echo "Create config for: ""$HOST_NET_MANAGMENT_IF_NAME"
    echo "$IF_MANAGMENT_CONFIG" > "$if_dir"/"$HOST_NET_MANAGMENT_IF_NAME"".nmconnection"
}


