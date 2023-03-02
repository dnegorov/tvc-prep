#!/bin/bash

. params.conf

echo
echo "####################################################"
echo "#                                                  #"
echo "#  Create ISO image with current params            #"
echo "#                                                  #"
echo "####################################################"
echo
echo

ISO_OUTPUT_DIR="./iso"
ISO_LABEL="$HOST_NAME"
ISO_FILE_NAME="$ISO_OUTPUT_DIR""/""$ISO_LABEL"".iso"

mkdir -p "$ISO_OUTPUT_DIR"
rm -rf "$ISO_OUTPUT_DIR""/*"

echo "Create ISO for: ""$HOST_NAME"
echo "Output file:    ""$ISO_FILE_NAME"
mkisofs -joliet -rock -volid "$ISO_LABEL" -output "$ISO_FILE_NAME" ./