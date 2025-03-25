#!/bin/bash

# example bash script to edit bigfix server plugin service configuration xml file
# this script uses sed to update the WaitPeriodSeconds value in the xml file
# the script takes two arguments: the file path and the new value

# NOTE: this works on linux but not macos due to the differences in sed

# filepath: /path/to/edit_xml_config_plugin.sh

# Usage: ./edit_xml_config_plugin.sh <file_path> <new_value>
# Example: ./bash/edit_xml_config_plugin.sh bash/edit_xml_config_plugin_example.xml 3600

# Exit if args are not provided
if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <file_path> <new_value>"
  exit 1
fi

FILE_PATH="$1"
NEW_VALUE="$2"

# Check if file exists
if [[ ! -f "$FILE_PATH" ]]; then
  echo "Error: File '$FILE_PATH' does not exist."
  exit 2
fi

# Check if new value is an integer
if ! [[ "$NEW_VALUE" =~ ^[0-9]+$ ]]; then
  echo "Error: New value must be an integer."
  exit 3
fi

# Use sed to update the WaitPeriodSeconds value
sed -i -E "s|(<WaitPeriodSeconds>)[0-9]+(</WaitPeriodSeconds>)|\1$NEW_VALUE\2|" "$FILE_PATH"

# Check if sed command was successful
if [[ $? -eq 0 ]]; then
  echo "Successfully updated WaitPeriodSeconds to $NEW_VALUE in '$FILE_PATH'."
else
  echo "Error: Failed to update WaitPeriodSeconds."
  exit 9
fi
