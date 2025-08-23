#!/bin/bash

################################################################################################
# File: install.sh
# Author: Eryone / Andreas
# Date: 20250602 / 20250823
# Purpose: Installs farm3d
#
################################################################################################

## replace to local home dir
path=$(echo ${HOME} | sed 's/\//\\\//g')                # Prepares home directory üath for sed command. Needed, because / is interpreted in sed as separaor for search/replace pattern.
#echo $path

echo "ℹ️  Set farm3d.service variables ..."
sed -i 's/~/'"$path"'/g'  ./farm3d.service              # Replace "~" in the file with the home directory
sed -i 's/User=pi/'User="$USER"'/g' ./farm3d.service

echo "ℹ️  pip install commands ..."
pip3 install websockets
#pip3 install opencv-python
#pip3 install qrcode[pil]
pip3 install paho-mqtt
pip3 install requests
pip3 install ConfigParser
pip3 install typing-extensions
pip3 install Pillow
pip3 install tqdm
pip3 install netifaces
pip3 install minio
pip3 install eventlet

echo "ℹ️  farm3d installer completed"
exit 0
