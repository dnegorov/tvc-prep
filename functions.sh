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


function ChangeParamInConf () {
    config_file=$1
    param_name=$2
    param_value=$3
    
}
