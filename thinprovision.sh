#!/bin/bash
#######################################################################################################
#This script can be used to initiate a build for DEP enrolled macs. It is for demonstration purposes.
#The contents of this script form the base of a possible DEP solution. The script needs to have the 
#Correct branding images deployed at enrollment complete. 
#######################################################################################################
#Variables
#######################################################################################################
iconpath="/Library/build/"
icon="logo.PNG"
heading1="Software Installation."
description1="Please wait while we install core business applications."
#######################################################################################################

# check that script is run as root user
if [ $EUID -ne 0 ]
then
    >&2 /bin/echo $'\nThis script must be run as the root user!\n'
   exit
fi

USERID=$(id -u $3)
# capture machine name

while true
do
name=$(/bin/launchctl asuser $USERID osascript -e 'Tell application "System Events" to display dialog "Please enter the name for your computer or select Cancel." default answer ""' -e 'text returned of result' 2>/dev/null)
    if [ $? -ne 0 ]     
    then # user cancel
        exit
    elif [ -z "$name" ]
    then # loop until input or cancel
        /bin/launchctl asuser $USERID osascript -e 'Tell application "System Events" to display alert "Please enter a name or select Cancel... Thanks!" as warning'
    else [ -n "$name" ] # user input
        break
    fi
done

scutil --set ComputerName $name
scutil --set LocalHostName $name
scutil --set HostName $name

# capture Asset tag
while true
do
tag=$(/bin/launchctl asuser $USERID osascript -e 'Tell application "System Events" to display dialog "Please enter the asset tag for your machine or select Cancel." default answer ""' -e 'text returned of result' 2>/dev/null)
    if [ $? -ne 0 ]     
    then # user cancel
        exit
    elif [ -z "$tag" ]
    then # loop until input or cancel
       /bin/launchctl asuser $USERID  osascript -e 'Tell application "System Events" to display alert "Please enter a name or select Cancel... Thanks!" as warning'
    else [ -n "$tag" ] # user input
        break
    fi
done

jamf recon -assetTag $tag

#Capture the new users short name

while true
do
shortname=$(/bin/launchctl asuser $USERID osascript -e 'Tell application "System Events" to display dialog "Please enter a  short name for the new user or select Cancel." default answer ""' -e 'text returned of result' 2>/dev/null)
    if [ $? -ne 0 ]     
    then # user cancel
        exit
    elif [ -z "$tag" ]
    then # loop until input or cancel
       /bin/launchctl asuser $USERID  osascript -e 'Tell application "System Events" to display alert "Please enter a  short name for the new user or select Cancel... Thanks!" as warning'
    else [ -n "$tag" ] # user input
        break
    fi
done



#Lock the screen to begin the software install.

/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType fs -icon "$iconpath$icon" -iconsize 2000 -heading "$heading1" -description "$description1" &


sleep 10

#Install applications.

jamf policy -trigger chrome
jamf policy -trigger vlc
jamf policy -trigger textmate

#Add FV2. 

jamf policy -trigger fv2

#Update Inventory

sudo jamf recon

#kill jamf helper

/usr/local/bin/jamf killJAMFHelper

#reboot
shutdown -r now
