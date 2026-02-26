#!/bin/bash
# A bash script to set bigfix client settings.
# https://support.hcl-software.com/csm?id=kb_article&sysparm_article=KB0022537
# Based upon: bash/config_set_value.sh

# Function to run sed in-place compatibly on both Mac (BSD) and Linux (GNU)
sed_inplace() {
    if [[ $(uname) == "Darwin" ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

config_ini_set_value() {
    local INI_FILE=$1
    local SECTION=$2
    local KEY=$3
    local VALUE=$4

    # 1. Create file if it doesn't exist
    if [ ! -f "$INI_FILE" ]; then
        touch "$INI_FILE"
    fi

    # 2. Check if the SECTION exists
    if grep -q "^\[$SECTION\]" "$INI_FILE"; then

        # 3. Check if the KEY exists specifically WITHIN that section
        # We use sed to extract the block from [SECTION] to the next [ or EOF,
        # then pipe to grep to see if the key is there.
        if sed -n "/^\[$SECTION\]/,/^\[/p" "$INI_FILE" | grep -q "^$KEY\s*="; then
            echo "Updating $KEY in section [$SECTION] to $VALUE"
            # Update the existing key inside the specific section range
            sed_inplace "/^\[$SECTION\]/,/^\[/s/^$KEY[[:space:]]*=.*/$KEY=$VALUE/" "$INI_FILE"
        else
            echo "Adding $KEY=$VALUE to existing section [$SECTION]"
            # Insert the new key after the section header.
            # We use a trick with 's' (substitute) to act as an append
            # because the 'a' command varies wildly between Mac and Linux.
            # We explicitly use a literal escaped newline for compatibility.
            sed_inplace "s/^\[$SECTION\]/\[$SECTION\]\\"$'
'"$KEY=$VALUE/" "$INI_FILE"
        fi
    else
        echo "Creating section [$SECTION] and adding $KEY=$VALUE"
        # Append new section and key to end of file
        # Using printf is safer/more portable than echo -e
        printf "\n[%s]\n%s=%s\n" "$SECTION" "$KEY" "$VALUE" >> "$INI_FILE"
    fi
}

file_base_name="besclient"

# if $3 starts with "bes", use it as the base name for the config file
if [[ "$3" == bes* ]]; then
    file_base_name="$3"
fi

# 1. Define the possible file paths in an array (order matters!)
paths=(
    "/var/opt/BESClient/$file_base_name.config"
    "./persistent/var/opt/BESClient/$file_base_name.config"
    "./var/opt/BESClient/$file_base_name.config"
    "./$file_base_name.config"
)

target_file=""

# 2. Loop through the array to find the first readable file
for file in "${paths[@]}"; do
    if [[ -r "$file" ]]; then
        target_file="$file"
        echo "Found config at: $target_file" >&2  # Optional: Prints to stderr so it doesn't mess up your output
        break # Stop looking once we find one!
    fi
done

# 3. If no file was found, throw an error and exit
if [[ -z "$target_file" ]]; then
    echo "Error: $file_name not found or not readable in any of the expected locations." >&2
    exit 1
fi

# Run the function with the provided arguments
config_ini_set_value "$target_file" "Software\BigFix\EnterpriseClient\Settings\Client\\$1" "value" "$2"

# Example Usage:
# bash bash/bigfix_settings_write_linux.sh "SettingName" "SettingValue"
# bash bash/bigfix_settings_write_linux.sh "SettingName" "SettingValue" "besexplorer"
