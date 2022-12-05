. params.conf

# full description is here /apidoc/index.html

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

# Return key from json
# Usage:
# JsonGetKey ".key_name"
# Examples:
# {"token": "123456789"}
# JsonGetKey ".token"
function JsonGetKey(){
	echo $(echo $1 | jq -r $2)
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

function LogIn(){
	local result=$($CURL_POST \
				$SU_APP_URL"/login" \
				-H 'accept: application/json' \
				-H 'Content-Type: application/x-www-form-urlencoded' \
				-d "username=$SU_USER_NAME&password=$SU_USER_PWD")
	JsonGetKey "$result" '.token'
}

function CurlGet(){
	local url=$1
	local result=$($CURL_GET \
				"$SU_API_URL""$url" \
				-H 'accept: application/json' \
				-H "Authorization: Bearer $(LogIn)")
	echo $result
}

function CurlPost(){
	local url=$1
	local data="$2"
	local result=$($CURL_POST \
				"$SU_API_URL""$url" \
				-H 'accept: */*' \
				-H "Authorization: Bearer $(LogIn)" \
				-H 'Content-Type: application/json' \
				-d "$data")
	echo $result
}

function CurlPut () {
	local url=$1
	local result=$($CURL_PUT \
				"$SU_API_URL""$url" \
				-H 'accept: */*' \
				-H "Authorization: Bearer $(LogIn)" \
				-H 'Content-Type: application/json')
	echo $result

}

function AppInit () {
	local url="/app/init"
	local data="lastname=""$(UrlEncode "$SU_LAST_NAME")""&firstname=""$(UrlEncode "$SU_FIRST_NAME")""&patronymic=""$(UrlEncode "$SU_PATRONYMIC")""&email=""$(UrlEncode "$SU_USER_EMAIL")""&password=""$(UrlEncode "$SU_USER_PWD")""&confirmPassword=""$(UrlEncode "$SU_USER_PWD")"
	local result=$($CURL_POST \
				   http://$SU_IP:$SU_PORT"/""$url" \
				   -H 'accept: application/json' \
				   -H 'Content-Type: application/x-www-form-urlencoded' \
				   -d "$data")
	echo $result
}

# Usage:
# GetMasterRealmID
function GetMasterRealmID(){
	local result=$(CurlGet)
	JsonGetKey "$result" '.id'
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
	JsonGetKey "$result" '.[0].id'
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


	echo $template
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
	echo $result
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

	echo $template
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
	echo $result
}


function GetStorageId(){
	local dc_id=$1
	local stor_name=$2
	local query=$(UrlEncode "in(storageName,""$stor_name"")")
	local url="/dcs/$dc_id/storages?query=$query"
	local result=$(CurlGet "$url")
	JsonGetKey "$result" '.[0].id.id'
}


# Get storage status
# Usage:
# GetStorageStatus "STOR_ID" "DC_ID"
function GetStorageStatus () {
	local stor_id="$1"
	local dc_id="$2"
	local "url=/dcs/""$dc_id""/storages/""$stor_id"
	local result=$(CurlGet "$url")
	JsonGetKey "$result" '.storageStatus'
}



function GetMacPoolId () {
	local pool_name="$1"
	local query=$(UrlEncode "in(poolName,""$pool_name"")")
	local url="/mac-address-pools?query=""$query"
	local result=$(CurlGet "$url")
	JsonGetKey "$result" '.[0].id'
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

	echo $template
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
	echo $result
}


function GetClusterID () {
	local cluster_name="$1"
	local dc_id="$2"
	local query=$(UrlEncode "in(clusterName,""$cluster_name"")")
	local url="/dcs/""$dc_id""/clusters?query=""$query"
	local result=$(CurlGet "$url")
	JsonGetKey "$result" '.[0].id.id'
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
	echo $result
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
	echo $result
}

# Activate host
# Usage:
# GetHostStatus "HOST_ID" "DC_ID"
function GetHostStatus () {
	local host_id="$1"
	local dc_id="$2"
	local "url=/dcs/""$dc_id""/hosts/""$host_id"
	local result=$(CurlGet "$url")
	JsonGetKey "$result" '.hostStatus'
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
	echo $result
}