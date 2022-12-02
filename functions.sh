. params.conf

# Escape chars: ~!@#$%^&*()_+=<>,.?/" \|[]
# Usage:
# var="192.168.1.1"
# EscapeChars "$var"
function EscapeChars () {
     echo $1 | sed -e 's/\([\[\/\.\,\<\>\#\%\(\)\^\:\;\ \"\~\*\?\$\@\!\+\=\&-\]\|\]\)/\\&/g'
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
    echo $(echo "$1" | sed 's/'$(EscapeChars $2)'/'$(EscapeChars $3)'/g')
}


# Get string from config file started with parameter name
# Usage:
# GetParamLineFromConfig "quarkus.artemis.url" "/opt/tvc/agent/config/application.properties"
# return: quarkus.artemis.url=tcp://localhost:61616?clientFailureCheckPeriod=5000&retryInterval=1000&reconnectAttempts=5&callTimeout=3000
function GetParamLineFromConfig () {
    param_name="$1"
    config_file="$2"
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
    param_name="$1"
    config_file="$2"
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
    param_name=$1
    param_value=$2
    config_file=$3
    sed -i 's/^'$(EscapeChars "$param_name")'=.*/'$(EscapeChars "$param_name")'\='$(EscapeChars "$param_value")'/g' "$config_file"
}


