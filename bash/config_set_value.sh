#!/bin/bash
# WORK IN PROGRESS: A simple script to set values in an INI configuration file.
echo "This script is a WORK IN PROGRESS and may not function as intended. Exiting."
exit 1

# so far this works to add a new section, but at least on macos it does not work to update existing keys

# Function to set an INI value
config_ini_set_value() {
    local INI_FILE=$1
    local SECTION=$2
    local KEY=$3
    local VALUE=$4

    # create the INI file if it doesn't exist
    if [ ! -f "$INI_FILE" ]; then
        touch "$INI_FILE"
    fi

    # Check if the key already exists in the section
    if grep -q "^\\[$SECTION\\]" "$INI_FILE" && grep -q "^$KEY=" "$INI_FILE"; then
        # Update existing key
        echo "Updating $KEY in section [$SECTION] to $VALUE"
        sed -i "/^\\[$SECTION\\]/,/^\\[/s/^$KEY=.*/$KEY=$VALUE/" "$INI_FILE"
    else
        # Add new key/section if it doesn't exist
        if grep -q "^\\[$SECTION\\]" "$INI_FILE"; then
            # Append to existing section
            echo "Adding $KEY=$VALUE to existing section [$SECTION]"
            sed -i "/^\\[$SECTION\\]/a\\$KEY=$VALUE" "$INI_FILE"
        else
            # Append new section and key to end of file
            echo "Creating section [$SECTION] and adding $KEY=$VALUE"
            echo -e "\n[$SECTION]\n$KEY=$VALUE" >> "$INI_FILE"
        fi
    fi
}

config_ini_set_value "$1" "$2" "$3" "$4"

# Example Usage:
# bash bash/config_set_value.sh "myconfig.ini" "database" "host" "192.168.1.1"
# bash bash/config_set_value.sh "myconfig.ini" "user" "name" "john_doe"
