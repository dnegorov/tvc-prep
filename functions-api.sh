. params.conf

# Full API description is here
# http://HOST_IP:8082/apidoc/index.html

CURL_GET="curl -s -X GET"
CURL_POST="curl -s -X POST"
CURL_PUT="curl -s -X PUT"
SU_API_URL="http://$SU_IP:$SU_PORT/api/realms/$REALM"
SU_APP_URL="http://$SU_IP:$SU_PORT/app/realms/$REALM"

function PrintSettings(){
	echo
	echo "PARAMS:"
	echo "	SU ADDRESS: "$SU_IP:$SU_PORT
	echo "	LOGIN:      "$SU_USER_NAME
	echo "	PASSWORD:   "$SU_USER_PWD
	echo "	APP URL:    "$SU_APP_URL
	echo "	API URL:    "$SU_API_URL
}

# Return key from JSON
# Usage:
# JsonGetKey ".key_name"
# Examples:
# JSON='{"token": "qwertyu"}'
# JsonGetKey "$JSON" ".token"
# Return: qwertyu
function JsonGetKey () {
	local json="$1"
	local param="$2"
	local result=$(echo "$json" | jq -r "$param")
	echo "$result"
}

# Change key in JSON
# Usage:
# String value must be in double quotes: '"string"':
# JsonChangeKey "{"json": "formated", "string": "or VARIABLE"}" ".key_name" '"NewStrValue"'
# Integer or boolean values must be without double quotes:
# JsonChangeKey "{"json": "formated", "string": "or VARIABLE"}" ".key_name" '1024'
# JsonChangeKey "{"json": "formated", "string": "or VARIABLE"}" ".key_name" 'true'
# JsonChangeKey "{"json": "formated", "string": "or VARIABLE"}" ".key_name" 'false'
#
# Return JSON formated string
#
# Examples:
# JSON='{"token": "123456789"}'
# JsonChangeKey "$JSON" ".token" '"P@$$w0rd"'
# Return: {"token": "P@$$w0rd"}
function JsonChangeKey () {
	local json="$1"
	local param_name="$2"
	local new_value="$3"
	local result=$(echo "$json" | jq -r "$param_name"' = '"$new_value")
	echo "$result"
}


# Return urlencoded sting
# Usage:
# UrlEncode 'P@$$w0rd'
# return: P%40%24%24w0rd
# UrlEncode 'Пароль'
# return: %D0%9F%D0%B0%D1%80%D0%BE%D0%BB%D1%8C
UrlEncode() {
  local string="${1}"
  local encoded=$(echo "$string" | \
  				  curl -Gso /dev/null -w %{url_effective} --data-urlencode @- "" \
				  | sed -E 's/..(.*).../\1/')
  echo "${encoded}"
}

# Return security token
# Used params from global config
# Usage:
# token=$(LogIn)
# Return: eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiI4NTIzZDk4Ny04MzNjLTQ4NmItOTM0Ni05ZjlmN2ZmZTJhZGMiLCJyb2xlcyI6WyJhZG1pbiJdLCJhdXRoX3RpbWUiOjE2NzAyMzIwNTcsImlzcyI6Imh0dHA6XC9cLzE5Mi4xNjguMTgwLjYwOjgwODJcL2FwcFwvcmVhbG1zXC9tYXN0ZXIiLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJhZG1pbiIsImdpdmVuX25hbWUiOiJBZG1pbm92IiwibWlkZGxlX25hbWUiOiJBZG1pbm92aWNoIiwiZXhwIjoxNjcwMjMyMTE3LCJmYW1pbHlfbmFtZSI6IkFkbWluIiwiaWF0IjoxNjcwMjMyMDU3LCJqdGkiOiI3MGFiNTQ1Yy1kMjQyLTRjYmEtYTVlMC00YzkxNDE2Njc0OWUiLCJlbWFpbCI6InN1cHBvcnRAc2thbGEtci5ydSJ9.DngmaitZk-sOh6UC0-9u0-NHAU2oAFlMC4U7DAib_iW8S0MbnH-ENAlTClHAx2uOKkUI47aLC6CRqHrLIZvxRb5Wc3TdLigSLJmwxubhrGT6jvYOjyKA5xQ66Lkk_HycfoY_7f-Sh04txebEYQO8je30qXKeAKjQpZi5Kq17achC9k10SB7vn9erylTnn6vYiOWjxulbA3ckdct6XPgZh3k5OxGUcJ_9fsyDrA1eNk1XxI8WviB1Kh_PqroBrii5wjFMrvjnXbg-0F6e0SE0E4wJA8PVkcHt_DzKUNLCKgKGu2fDZehfj69mONQelw3EBhzO8mK-sBb0sYmr_PLSGA
# Function used in:
# 	CurlGet
#	CurlPost
#	CurlPut
# Get token for use in http://HOST_IP:8082/apidoc/index.html do in console:
# . functions-api.sh
# echo $(LogIn)
# Copy token and paste to Authorization field
function LogIn(){
	local result=$($CURL_POST \
				$SU_APP_URL"/login" \
				-H 'accept: application/json' \
				-H 'Content-Type: application/x-www-form-urlencoded' \
				-d "username=$SU_USER_NAME&password=$SU_USER_PWD")
	echo $(JsonGetKey "$result" '.token')
}

# Do curl -X GET
# Usage:
# CurlGet "/API/FUNCTION/REQUST"
# Example:
# CurlGet "/dcs/$dc_id/storages?query=$query"
function CurlGet(){
	local url=$1
	local result=$($CURL_GET \
				"$SU_API_URL""$url" \
				-H 'accept: application/json' \
				-H "Authorization: Bearer $(LogIn)")
	echo "$result"
}

# Do curl -X POST
# Usage:
# CurlPost "/API/FUNCTION/REQUST" "data"
# Parameter data is optional
# Example:
# CurlPost "/dcs/$dc_id/storages?hostId=$host_id" 
function CurlPost(){
	local url=$1
	local data="$2"
	local result=$($CURL_POST \
				"$SU_API_URL""$url" \
				-H 'accept: */*' \
				-H "Authorization: Bearer $(LogIn)" \
				-H 'Content-Type: application/json' \
				-d "$data")
	echo "$result"
}

# Do curl -X PUT
# Usage:
# CurlPut "/API/FUNCTION/REQUST" "data"
# parameter "data" is optional
# Example:
# CurlPut ""/dcs/""$dc_id""/hosts/""$host_id""/activate"" $JSON
function CurlPut () {
	local url=$1
	local data="$2"
	local result=$($CURL_PUT \
				"$SU_API_URL""$url" \
				-H 'accept: */*' \
				-H "Authorization: Bearer $(LogIn)" \
				-H 'Content-Type: application/json' \
				-d "$data")
	echo "$result"

}

# Init admin user with params in global config
# Usage:
# AppInit
function AppInit () {
	local url="/app/init"
	local data="lastname=""$(UrlEncode "$SU_LAST_NAME")""&firstname=""$(UrlEncode "$SU_FIRST_NAME")""&patronymic=""$(UrlEncode "$SU_PATRONYMIC")""&email=""$(UrlEncode "$SU_USER_EMAIL")""&password=""$(UrlEncode "$SU_USER_PWD")""&confirmPassword=""$(UrlEncode "$SU_USER_PWD")"
	local result=$($CURL_POST \
				   http://$SU_IP:$SU_PORT"/""$url" \
				   -H 'accept: application/json' \
				   -H 'Content-Type: application/x-www-form-urlencoded' \
				   -d "$data")
	echo "$result"
}

# Usage:
# GetMasterRealmID
function GetMasterRealmID(){
	local result=$(CurlGet)
	echo $(JsonGetKey "$result" '.id')
}

# Usage:
# GetDCID "DC name"
# Examples:
# Get dc_id for default DC
# GetDCID "default"
function GetDCID(){
	local dc_name=$1
	local query=$(UrlEncode "in(dcName,""$dc_name"")")
	local url="/dcs?query=$query"
	local result=$(CurlGet "$url")
	echo $(JsonGetKey "$result" '.[0].id')
}

# Usage:
# NFSStorageTemplate "Storage name" "is master (true/false)" "NFS server IP" "share path" "storage type"
# Examples:
# Master storage for VMs disks
# NFSStorageTemplate "Storage-HDD" "true" "192.168.1.10" "/storage/hdd" "DATA"
# Storage for ISO disks
# NFSStorageTemplate "Storage-ISO" "false" "192.168.1.10" "/storage/iso" "ISO"
function NFSStorageTemplate(){
	local stor_name="$1"
	local stor_description="$stor_name"
	local stor_master="$2" # true false
	local stor_address="$3"
	local stor_port=2049 # standart NFS port 2049
	local stor_pool="NET_FS" # DIR, FIBRE_CHANNEL, ISCSI, NET_FS
	local stor_netFS="NFS" # AUTO, NFS
	local stor_NFS_ver=4 # 3 4
	local stor_path="$4"
	local stor_type="$5" # BACKUP, DATA, EXTERNAL, ISO
	local template='{"luns": [
								{
								"connections": [
									{
									"attributes": {
										"iface": "default",
										"iqn": "iqn.2021-11.agent.centos:centos-8",
										"tpg": "1"
									},
									"host": {
										"port": 3260,
										"name": "192.168.122.167"
									},
									"password": "password",
									"username": "user"
									}
								],
								"deviceType": "SCSI",
								"discardMaxBytes": 0,
								"dm": "dm-9",
								"firmware": "4.0",
								"id": {
									"dcId": "19865dec-e6f8-4834-a23e-54bf4d493166",
									"lunId": "19865dec-e6f8-4834-a23e-54bf4d493166",
									"storageId": "19865dec-e6f8-4834-a23e-54bf4d493166"
								},
								"logicalBlockSize": 512,
								"lunSize": 3221225472,
								"model": "block2",
								"physicalBlockSize": 512,
								"serial": "SLIO-ORG_block2_2a5d25f9-529c-4c59-bfc2-58c76f8f719e",
								"status": "FREE",
								"vendor": "LIO-ORG"
								}
							],
							"master": '$stor_master',
							"poolType": "'$stor_pool'",
							"storageName": "'$stor_name'",
							"storagePath": "'$stor_path'",
							"storageType": "'$stor_type'",
							"mountOpts": [
								"soft",
								"nosharecache",
								"timeo=100",
								"retrans=3",
								"nolock"
							],
							"netFsFormat": "'$stor_netFS'",
							"netFsProtocol": '$stor_NFS_ver',
							"sourceHosts": [
								{
								"port": '$stor_port',
								"name": "'$stor_address'"
								}
							]
							}'


	echo "$template"
}


# Usage:
# CreateNFSStorage "DC-ID" "Host-ID" "Storage name" "is master (true/false)" "NFS server IP" "share path" "storage type"
# Examples:
# Master storage for VMs disks
# CreateNFSStorage "Storage-HDD" "true" "192.168.1.10" "/storage/hdd" "DATA"
# Storage for ISO disks
# CreateNFSStorage "$DC-ID" "$HOST-ID" "Storage-ISO" "false" "192.168.1.10" "/storage/iso" "ISO"
function CreateNFSStorage(){
	local dc_id=$1
	local host_id=$2
	local stor_name=$3
	local stor_master=$4
	local stor_ip=$5
	local stor_path=$6
	local stor_type=$7
	local url="/dcs/$dc_id/storages?hostId=$host_id"
	# NFSStorageTemplate "Storage-HDD" "true" "192.168.1.10" "/storage/hdd" "DATA"
	local data=$(NFSStorageTemplate "$stor_name" "$stor_master" "$stor_ip" "$stor_path" "$stor_type")
	#echo LOG: $data
	local result=$(CurlPost "$url" "$data")
	echo "$result"
}


# Usage:
# LocalStorageTemplate "Storage name" "is master (true/false)" "hdd path" "storage type"
# Examples:
# Master storage for VMs disks
# LocalStorageTemplate "Storage-HDD" "true" "/storage/hdd" "DATA"
function LocalStorageTemplate(){
	local stor_name="$1"
	local stor_description="$stor_name"
	local stor_master="$2" # true false
	local stor_pool="DIR" # DIR, FIBRE_CHANNEL, ISCSI, NET_FS
	local stor_path="$3"
	local stor_type="$4" # BACKUP, DATA, EXTERNAL, ISO
	local template='{
					"storageName": "'$stor_name'",
					"storageType": "'$stor_type'",
					"poolType": "'$stor_pool'",
					"storagePath": "'$stor_path'",
					"sourceHosts": [],
					"luns": [],
					"connections": [],
					"master": '$stor_master'
				}'

	echo "$template"
}

# Usage:
# CreateLocalStorage "Storage name" "is master (true/false)" "hdd path" "storage type" "DC ID" "HOST ID"
# Examples:
# Master storage for VMs disks
# CreateLocalStorage "Storage-HDD" "true" "/storage/hdd" "DATA" "$DC_ID" "$HOST-ID"
function CreateLocalStorage(){
	local stor_name="$1"
	local stor_description="$stor_name"
	local stor_master="$2" # true false
	local stor_path="$3"
	local stor_type="$4" # BACKUP, DATA, EXTERNAL, ISO
	local dc_id="$5"
	local host_id="$6"
	local url="/dcs/$dc_id/storages?hostId=$host_id"
	# LocalStorageTemplate "Storage-HDD" "true" "/storage/hdd" "DATA"
	local data=$(LocalStorageTemplate "$stor_name" "$stor_master" "$stor_path" "$stor_type" "$dc_id")
	#echo LOG: $data
	local result=$(CurlPost "$url" "$data")
	echo "$result"
}

# Get storage ID
# Usage:
# GetStorageStatus "DC_ID" "Storage Name"
function GetStorageId(){
	local dc_id=$1
	local stor_name=$2
	local query=$(UrlEncode "in(storageName,""$stor_name"")")
	local url="/dcs/$dc_id/storages?query=$query"
	local result=$(CurlGet "$url")
	echo $(JsonGetKey "$result" '.[0].id.id')
}


# Get storage status
# Usage:
# GetStorageStatus "STOR_ID" "DC_ID"
function GetStorageStatus () {
	local stor_id="$1"
	local dc_id="$2"
	local "url=/dcs/""$dc_id""/storages/""$stor_id"
	local result=$(CurlGet "$url")
	echo $(JsonGetKey "$result" '.storageStatus')
}


# Get MAC pool ID
# Usage:
# GetMacPoolId "Pool Name"
function GetMacPoolId () {
	local pool_name="$1"
	local query=$(UrlEncode "in(poolName,""$pool_name"")")
	local url="/mac-address-pools?query=""$query"
	local result=$(CurlGet "$url")
	echo $(JsonGetKey "$result" '.[0].id')
}


# Usage:
# DCTemplate "DC-name" "DC-description" "is local (true/false)" "MAC ADDRESS POOL ID" "MAXIMUM HOSTS IN DC"
# Examples:
# Create local DC
# DCTemplate "Local-DC" "Local-DC-new" "true" "98c4d393-af2b-442b-918d-db40d7e8acf3" "2000"
function DCTemplate () {
	local dc_name="$1"
	local dc_description="$2"
	local dc_local="$3"
	local dc_mac_address_pool="$4"
	local dc_max_hosts="$5"
	local template='{
					"dcDescription": "'$dc_description'",
					"dcName": "'$dc_name'",
					"eventSettings": [
						{
						"category": "DCS",
						"daysCount": 365,
						"id": {
							"dcId": "19865dec-e6f8-4834-a23e-54bf4d493166",
							"id": "19865dec-e6f8-4834-a23e-54bf4d493166"
						}
						}
					],
					"local": '$dc_local',
					"macAddressPoolId": "'$dc_mac_address_pool'",
					"maxHostsCount": '$dc_max_hosts'
					}'

	echo "$template"
}


# Usage:
# CreateDC "DC-name" "DC-description" "is local (true/false)" "MAC ADDRESS POOL ID" "MAXIMUM HOSTS IN DC"
# Examples:
# Create local DC
# CreateDC "Local-DC" "Local-DC-new" "true" "98c4d393-af2b-442b-918d-db40d7e8acf3" "2000"
function CreateDC () {
	local url="/dcs"
	local dc_name="$1"
	local dc_description="$2"
	local dc_local="$3"
	local dc_mac_address_pool="$4"
	local dc_max_hosts="$5"
	# DCTemplate "Local-DC" "Local-DC-new" "true" "98c4d393-af2b-442b-918d-db40d7e8acf3" "2000"
	local data=$(DCTemplate "$dc_name" "$dc_description" "$dc_local" "$dc_mac_address_pool" "$dc_max_hosts")
	#echo LOG: $data
	local result=$(CurlPost "$url" "$data")
	echo "$result"
}

# Get Cluster ID
# Usage:
# GetMacPoolId "Cluster Name" "DC_ID"
function GetClusterID () {
	local cluster_name="$1"
	local dc_id="$2"
	local query=$(UrlEncode "in(clusterName,""$cluster_name"")")
	local url="/dcs/""$dc_id""/clusters?query=""$query"
	local result=$(CurlGet "$url")
	echo $(JsonGetKey "$result" '.[0].id.id')
}

# Add host to clusster in DC
# Usage:
# AddHostToCluster "HOST_ID" "CLUSTER_ID" "DC_ID"
function AddHostToCluster () {
	local host_id="$1"
	local cluster_id="$2"
	local dc_id="$3"
	local url="/dcs/""$dc_id""/hosts/""$host_id""/joinCluster/""$cluster_id"
	# echo LOG: ${FUNCNAME[0]}": "$url
	local result=$(CurlPut "$url")
	echo "$result"
}

# Activate host
# Usage:
# ActivateHost "HOST_ID" "DC_ID"
function ActivateHost () {
	local host_id="$1"
	local dc_id="$2"
	local url="/dcs/""$dc_id""/hosts/""$host_id""/activate"
	# echo LOG: ${FUNCNAME[0]}": "$url
	local result=$(CurlPut "$url")
	echo "$result"
}

# Activate host
# Usage:
# GetHostStatus "HOST_ID" "DC_ID"
function GetHostStatus () {
	local host_id="$1"
	local dc_id="$2"
	local "url=/dcs/""$dc_id""/hosts/""$host_id"
	local result=$(CurlGet "$url")
	echo $(JsonGetKey "$result" '.hostStatus')
}


# Set host as SPM (Storage Primary Master)
# Usage:
# ActivateHost "HOST_ID" "DC_ID"
function SetHostSPM () {
	local host_id="$1"
	local dc_id="$2"
	local url="/dcs/""$dc_id""/hosts/""$host_id""/switch/spm"
	# echo LOG: ${FUNCNAME[0]}": "$url
	local result=$(CurlPut "$url")
	echo "$result"
}


# Create NetworkEntity with minimal set of properties
# Usage:
# NewNet=$(NetworkEntityTemplate)
# Return: '{"networkName": "EXAMPLE", "description": "EXAMPLE", "vlanId": null, "mtu": 1500, "vmNetwork": true,	"portIsolation": false,	"dnsServers": []}'
function NetworkEntityTemplate () {
	local template='{
					"networkName": "EXAMPLE",
					"description": "EXAMPLE",
					"vlanId": null,
					"mtu": 1500,
					"vmNetwork": true,
					"portIsolation": false,
					"dnsServers": []
					}'
	echo "$template"
}


# Get network parameter from NetworkEntity JSON
# Usage:
# GetNetworkParameter "NetworkEntity in JSON" "Param Name"
# Return: value string 
# Example:
# GetNetworkParameter "$(GetNetwork $(GetNetworkID "tvcmgmt" "$DC_ID") "$DC_ID")" ".networkName"
# Return: tvcmgmt
# Parameters examples:
# root of JSON . = {}
# {"param":"value"}
# .param = "value"
# {"param":{"subParam1":"value1", "subParam2":"value2"}}
# .param.subParam1 = "value1"
# {"list":["192.168.10.10", "192.168.10.11"]}
# .list[0] = "192.168.10.10"
# {[{"param":{"subParam1":"value1", "subParam2":"value2"}}, {"param":{"subParam1":"value3", "subParam2":"value4"}}]}
# .[1].param.subParam2 = "value4"
function GetNetworkParameter () {
	local network="$1"
	local param_name="$2"
	local result=$(JsonGetKey "$network" "$param_name")
	echo "$result"
}

# Change key in NetworkEntity JSON
# Usage:
# SetNetworkParameter "$NetworkEntity" "KeyName" "NewValue"
# Value types as in JSON standart:
# strings: "string" must be in ""
# integers: 123
# boolean: true false
#
# Examples:
# Add а list of DNS servers (ip as a string)
# SetNetworkParameter "$(GetNetwork $NET_ID $DC_ID)" ".dnsServers" '["8.8.8.8", "77.88.8.8 "]'
# Enable port mirroring
# SetNetworkParameter "$(GetNetwork $NET_ID $DC_ID)" ".portMirroring" 'true'
# Change MTU
# SetNetworkParameter "$(GetNetwork $NET_ID $DC_ID)" ".mtu" '9000'
# Key names starts with . (root)
# .hostname
# .key.subkey
# .list[1].key.subkey
#
# See comments for JsonChangeKey
function SetNetworkParameter () {
	local network="$1"
	local param_name="$2"
	local new_value="$3"
	local result=$(JsonChangeKey "$network" "$param_name" "$new_value")
	echo "$result"
}


# Get network properties
# Usage:
# GetNetwork "Network_ID" "DC_ID"
# Return: NetworkEntity in JSON 
function GetNetwork () {
	local net_id="$1"
	local dc_id="$2"
	local url="/dcs/""$dc_id""/networks/""$net_id"
	local result=$(CurlGet "$url")
	echo "$result"
}

# Get Network ID
# Usage:
# GetNetworkID "Network Name" "DC_ID"
function GetNetworkID () {
	local network_name="$1"
	local dc_id="$2"
	local query=$(UrlEncode "in(networkName,""$network_name"")")
	local url="/dcs/""$dc_id""/networks?query=""$query"
	local result=$(GetNetworkParameter "$(CurlGet "$url")" '.[0].id.id')
	echo "$result"
}


# Change network
# Usage:
# ChangeNetwork "NET_ID" "$NetworkEntity"
# Example:
# NetworkEntity=$(NetworkEntityTemplate)
# NetworkEntity=SetNetworkParameter "$NetworkEntity" ".networkName" '"INTERCONNECT"'
# ChangeNetwork "$DC_ID" "$NetworkEntity"
function ChangeNetwork () {
	local net_id="$1"
	local dc_id="$2"
	local network="$3"
	local url="/dcs/""$dc_id""/networks/""$net_id"
	local result=$(CurlPut "$url" "$network")
	echo "$result"
}

# Create network
# Usage:
# CreateNetwork "DC_ID" "$NetworkEntity"
# Example:
# NetworkEntity=$(GetNetwork $NET_ID $DC_ID)
# NetworkEntity_new=SetNetworkParameter "$(GetNetwork $NET_ID $DC_ID)" ".mtu" '9000'
# ChangeNetwork "$NET_ID" "$DC_ID" "$NetworkEntity_new"
function CreateNetwork () {
	local dc_id="$1"
	local network="$2"
	local url="/dcs/""$dc_id""/networks/"
	local result=$(CurlPost "$url" "$network")
	echo "$result"
}

# Create cluster network properties
# Usage:
# SetClusterNetRoles "required" "management" "display" "migration" "storage" "default_route"
#
# Example:
# Create network for STORAGE only
# SetClusterNetRoles "true" "false" "false" "true" "storage" "false"
#
# PARAMETERS ARE BOOLEAN CAN BE ONLY "true" OR "false"
# 1 required      - must be on every host
# 2 management    - used as managment
# 3 display       - used for vnc access
# 4 migration     - used for migration
# 5 storage       - used for storage networks
# 6 default_route - used for default gateway
function SetClusterNetRoles () {
	local network_id=""
	local cluster_id=""
	local required="$1"
	local management="$2"
	local display="$3"
	local migration="$4"
	local storage="$5"
	local default_route="$6"
	local template='{
					"defaultRoute": '"$default_route"',
					"display": '"$display"',
					"id": {
						"networkId": "'"$network_id"'",
						"clusterId": "'"$cluster_id"'"
					},
					"management": '"$management"',
					"migration": '"$migration"',
					"required": '"$required"',
					"storage": '"$storage"'
					}'
	echo "$template"
}


# Applay to network to cluster
# Usage:
# ApplyNetToCluster "DC_ID" "NET_ID" "CLUSTER_ID" "NET_ROLES"
function ApplyNetToCluster () {
	local dc_id="$1"
	local net_id="$2"
	local cluster_id="$3"
	local net_roles="$4"
	net_roles=$(JsonChangeKey "$net_roles" ".id.networkId" '"'"$net_id"'"')
	net_roles=$(JsonChangeKey "$net_roles" ".id.clusterId" '"'"$cluster_id"'"')
	local url="/dcs/""$dc_id""/networks/""$net_id""/cluster-networks"
	local result=$(CurlPost "$url" "$net_roles")
	echo "$result"
}

# Add to NetDeploymentEntity new network profile
# Usage:
# AddNetworkToNetDeploymentEntity "NetDeployEntity" "PROFILE_NUMBER" "NETWORK_ID" "DC_ID"
# Return: NetDeploymentEntity in JSON formated string
function AddNetworkToNetDeploymentEntity () {
	local deployment="$1"
	local profile_number='.networkProfiles['"$2"']'
	local net_id="$3"
	local dc_id="$4"
	local network=$(GetNetwork "$net_id" "$dc_id")
	local net_profiles=$(GetNetworkParameter "$network" '.networkProfiles[0]')
	deployment=$(JsonChangeKey "$deployment" "$profile_number" "$net_profiles")
	echo "$deployment"
}

# Create NetDeploymentEntity with first network profile (.networkProfiles[0])
# Usage:
# CreateNetDeploymentEntity "DEPLOYMENT_NAME" "ENABLED" "NET_ID" "DC_ID"
# Return: NetDeploymentEntity in JSON formated string
# Parameter ENABLED must be true or false
function CreateNetDeploymentEntity () {
	local deployment_name="$1"
	local enabled="$2"
	local net_id="$3"
	local dc_id="$4"
	local deployment_descr="$deployment_name"
	local network=$(GetNetwork "$net_id" "$dc_id")
	local net_profiles=$(GetNetworkParameter "$network" '.networkProfiles[0]')
	local template='{
					"deploymentDescription": "'"$deployment_descr"'",
					"deploymentName": "'"$deployment_name"'",
					"enabled": '"$enabled"'
					}'
	template=$(JsonChangeKey "$template" ".networkProfiles[0]" "$net_profiles")
	echo "$template"
}

# Applay NetDeploymentEntity to DC
# Usage:
# ApplayNetDeployment "DC_ID" "NetDeployEntity"
function ApplayNetDeployment () {
	local dc_id="$1"
	local deployment="$2"
	local url="/dcs/""$dc_id""/network-deployments"
	local result=$(CurlPost "$url" "$deployment")
	echo "$result"
}

# Create ComputeDeploymentEntity
# Usage:
# CreateComputeDeploymentEntity "DEPLOYMENT_NAME" "CPU_CORES_MIN" "CPU_CORES_MAX" "CPU_SPEED_MIN" "CPU_SPEED_MAX" "RAM_MIN" "RAM_MAX" "VRAM_MAX"
# Return: ComputeDeploymentEntity in JSON formated string
# Parameters:
# DEPLOYMENT_NAME: string 
# CPU_CORES_MIN: integer (from 1 to 512 max)
# CPU_CORES_MAX: integer (from CPU_CORES_MIN to 512 max)
# CPU_SPEED_MIN: integer (in MHz from 500 to 10000 max)
# CPU_SPEED_MAX: integer (in MHz from CPU_SPEED_MIN to 10000 max)
# RAM_MIN: integer (in Mb from 16 to 655360 max)
# RAM_MAX: integer (in Mb from RAM_MIN to 655360 max)
# VRAM_MAX: integer (in Mb from 32 to 1024 max)
function CreateComputeDeploymentEntity () {
	local deployment_name="$1"
	local cpu_cores_min="$2"
	local cpu_cores_max="$3"
	local cpu_speed_min="$4"
	local cpu_speed_max="$5"
	local ram_min="$6"
	local ram_max="$7"
	local vram_max="$8"
	local cpu_arch="x86_64"
	local chipset_types='["I440FX", "Q35"]'
	local enabled="true"
	local cpu_model="null"
	local ha="false"
	local nested_virtualization="true"
	local volatile_vm="false"
	local deployment_desc="$deployment_name"
	local template='{
					"deploymentDescription": "'"$deployment_name"'",
					"deploymentName": "'"$deployment_desc"'",
					"enabled": '"$enabled"',
					"chipsetTypes": '"$chipset_types"',
					"coreCountMax": '"$cpu_cores_max"',
					"coreCountMin": '"$cpu_cores_min"',
					"cpuArch": "'"$cpu_arch"'",
					"cpuModel": '"$cpu_model"',
					"cpuSpeedMax": '"$cpu_speed_max"',
					"cpuSpeedMin": '"$cpu_speed_min"',
					"ha": '"$ha"',
					"nestedVirtualization": '"$nested_virtualization"',
					"ramMax": '"$ram_max"',
					"ramMin": '"$ram_min"',
					"volatileVm": '"$volatile_vm"',
					"vramMax": '"$vram_max"'
					}'
	echo "$template"
}


# Applay ComputeDeploymentEntity to DC
# Usage:
# ApplayComputeDeployment "DC_ID" "ComputeDeploymentEntity"
function ApplayComputeDeployment () {
	local dc_id="$1"
	local deployment="$2"
	local url="/dcs/""$dc_id""/compute-deployments"
	local result=$(CurlPost "$url" "$deployment")
	echo "$result"
}


function GetDCparams () {
	local dc_id=$(GetDCID "$DC_NAME")
	local cluster_id=$(GetClusterID 'Основной' "$dc_id")
	local mgmtnet_id=$(GetNetworkID 'tvcmgmt' "$dc_id")
	local mgmtnet=$(GetNetwork "$mgmtnet_id" "$dc_id")
	local mgmtnet_profile_id=$(GetNetworkParameter "$mgmtnet" '.networkProfiles[0].id.id')
	echo
	echo "Security token: "
	echo $(LogIn)
	echo
	echo "DC Parameters"
	echo " Realm:              "$REALM
	echo " DC name:            "$DC_NAME
	echo " DC-ID:              "$dc_id
	echo " Cluster ID:         "$cluster_id
	echo " Host ID:            "$AGENT_NODE_ID
	echo " tvcmgmt Net ID:     "$mgmtnet_id
	echo " tvcmgmt Profile ID: "$mgmtnet_profile_id
	echo 
}