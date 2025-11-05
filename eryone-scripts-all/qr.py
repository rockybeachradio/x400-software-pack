################################################################################################
# File: qr.py
# Author: Eryone
# Date: 202500711
# purpose: Creates a QR code which contains the hostname:mac-Adress ans saves it as a png image.
#
# How to call: ???
# Called in ???
################################################################################################

import netifaces as ni
import qrcode

ipmac = ni.ifaddresses('eth0')[ni.AF_LINK][0]["addr"]       # Fetches the MAC address of interface eth0.

file1 = open("/etc/hostname", "r")                          # Open the hostname file in read only. Adressable via file1
ipmac = file1.read().replace('\n', '') + ":" + ipmac        # reads the content of the file. saves the hostname forom the file and the mac-adress to teh iqmac variable
file1.close()                                               # CLoses the file

img = qrcode.make(ipmac)        # Creates a QRcode based on the variable iqmac
img.save("/tmp/qrcode.png")     # saves the QRcode als png file
