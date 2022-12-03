. params.conf

# Escape chars: ~!@#$%^&*()_+=<>,.?/" \|[]
# Usage:
# var="192.168.1.1"
# EscapeChars "$var"
function EscapeChars () {
     echo "$1" | sed -e 's~\([\[\/\.\,\<\>\#\%\(\)\^\:\;\"\*\?\$\@\!\+\=\&-\_\]\|\]\)~\\&~g' | sed -e 's~\ ~\\x20~g' 
}



# Replace change substring in string (using EscapeChars for parameters)
# Usage:
# source_str="http:\\192.168.1.1\app"
# sub_str="192.168.1.1"
# new_sub_str="10.1.1.10"
# StrReplace "$source_str" "$sub_str" "$new_sub_str"
# result: "http:\\10.1.1.10\app"
#
# WARNING !!!
# in result string all repeatable spaces will be replaced by single space:
# "Param   Pam    Pam" -> "Param Pam Pam"
function StrReplace() {
    local string="$1"
    local sub_string="$2"
    local replace_string="$3"
    echo $(echo "$string" | sed 's~'$(EscapeChars "$sub_string")'~'$(EscapeChars "$replace_string")'~g')
}


# Get string from config file started with parameter name
# Usage:
# GetParamLineFromConfig "quarkus.artemis.url" "/opt/tvc/agent/config/application.properties"
# return: quarkus.artemis.url=tcp://localhost:61616?clientFailureCheckPeriod=5000&retryInterval=1000&reconnectAttempts=5&callTimeout=3000
function GetParamLineFromConfig () {
    local param_name="$1"
    local config_file="$2"
    # grep -v '^\s*$\|^#\|^\s*\#' 
    # excludes empty lines 
    # or lines with only spaces, lines beginning with #, 
    # and lines containing nothing but spaces before #.
    cat "$config_file" | grep -v '^\s*$\|^#\|^\s*\#' | grep "$param_name"
}

# Get string from config file started with parameter name
# Usage:
# GetParamValueFromConfig "quarkus.artemis.url" "/opt/tvc/agent/config/application.properties"
# return: tcp://localhost:61616?clientFailureCheckPeriod=5000&retryInterval=1000&reconnectAttempts=5&callTimeout=3000
function GetParamValueFromConfig () {
    local param_name="$1"
    local config_file="$2"
    # awk set delimeter as 'params_name=' and return the end of string
    GetParamLineFromConfig "$param_name" "$config_file" | awk -F"$param_name""=" '{print $2}'
}


# Set parameter in config file
# Usage:
# SetParamInConfig "quarkus.artemis.password" 'P@$$w0rd' "/opt/tvc/agent/config/application.properties"
# 
# Warninig !!!
# If parameter does not exist or is commented, it will not be added or changed.
function SetParamInConfig () {
    local param_name="$1"
    local param_value="$2"
    local config_file="$3"
    local new_str=$(EscapeChars "$param_name"'='"$param_value")
    echo ${FUNCNAME[0]}":"
    echo "Change config: "$config_file
    echo "    Parameter: "$param_name
    echo "        Value: "$param_value
    sed -i 's~^'$(EscapeChars $param_name)'=.*~'$new_str'~g' "$config_file"
}

# Set list of parameters in config file
# Usage:
# SetParamListInConfig param_list /path/to/config
#
# Param_list declaration: 
# declare -A param_list=(
#    ["param_name1"]="param_value1"
#    ["param_name2"]="param_value2"
# )
#
# Warninig !!!
# If parameter does not exist or is commented, it will not be added or changed.
function SetParamListInConfig () {
    local -n list="$1"
    local config_file="$2"
    echo ${FUNCNAME[0]}":"
    echo "Processing config list for: "$config_file
    for param in ${!list[@]}
        do
            SetParamInConfig "$param" "${list[$param]}" "$config_file"
        done
}

# Add string to the end of file if not exist
# Usage:
# ApendFileUniqStr "String to add" /path/to/file
function ApendFileUniqStr () {
    local str_to_add="$1"
    local file_path="$2"
    echo ${FUNCNAME[0]}":"
    echo "Add string: ""$str_to_add"
    echo "   to file: ""$file_path"
    grep -qF "$str_to_add" "$file_path"  || echo "$str_to_add" | sudo tee --append "$file_path"
}

# Format and mount disk for storage
# Usage:
# PrepareStorageDisk /device/path /mount/point
# Example:
# PrepareStorageDisk /dev/sdb /storage
function PrepareStorageDisk () {
    local disk_device="$1"
    local mount_dir="$2"
    local partition=$disk_device"1"

    echo ${FUNCNAME[0]}":"
    echo "Create mount point: "$mount_dir
    mkdir -p "$mount_dir"

    echo "Create partition on: "$disk_device
    parted $disk_device -s mktable gpt mkpart primary ext4 1M 100%
    
    echo "Format partition: "$partition
    mkfs.ext4 -F $partition

    echo "Add partition to /etc/fstab: "$partition
    mntstr=$(blkid $partition | awk '{print $2}')" $mount_dir ext4 rw,seclabel,relatime 0 0"
    ApendFileUniqStr "$mntstr" "/etc/fstab"
    mount -a
}



# Prepare storage dirs
# Usage:
# PrepareStorageDirs /disk/mount/point iso_dir_name hdd_dir_name
# Example:
# PrepareStorageDirs /storage iso hdd
function PrepareStorageDirs () {
    local mount_dir="$1"
    local iso_dir="$2"
    local hdd_dir="$3"
    echo ${FUNCNAME[0]}":"
    echo -n "Create directories: "
    echo -e "\n ->""$mount_dir"/{"$iso_dir","$hdd_dir"}
    mkdir -p "$mount_dir"/{"$iso_dir","$hdd_dir"}

    echo "Change owner: "$mount_dir
    chown -R tvc "$mount_dir"
}

# Prepare NFS share
# Usage:
# NFSAddShare /storage/iso $NFS_SHARE_PARAM_FOR_EXPORT
function NFSAddShare () {
    local share_dir="$1"
    local share_param="$2"
    local exports_file="/etc/exports"
    echo ${FUNCNAME[0]}":"
    echo "Add path to /etc/exports: "$share_dir
    local share="$share_dir"" ""$share_param"
    ApendFileUniqStr "$share" "$exports_file"
}

# Start NFS server and export shares
function EnableNFS () {
    echo ${FUNCNAME[0]}":"
    echo "Enable and start NFS server:"
    systemctl enable --now nfs-server
    echo "Enable exports:"
    exportfs -a
}


