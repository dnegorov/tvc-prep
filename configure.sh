. params.conf
. functions-api

PrintSettings

echo
echo $(LogIn)

echo
REALM_ID=$(GetMasterRealmID)
echo "Realm_ID:   "$REALM_ID

DEFAULT_DC_ID=$(GetDCID "$DC_NAME")
echo "Default DC: "$DEFAULT_DC_ID

storname=$STOR_HDD_NAME
#result=$(CreateNFSStorage $DEFAULT_DC_ID $HOST_ID $storname "true" $STOR_SRV_IP "/storage/hdd2" "DATA")
echo Storage creation:
echo "  Name:       "$storname
echo "  Result:     "$result
STOR_ID=$(GetStorageId "$DEFAULT_DC_ID" "$storname")
echo "  Storage ID: "$STOR_ID



