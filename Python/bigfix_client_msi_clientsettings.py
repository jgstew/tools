"""
edit bigfix client MSI to incorporate custom client settings.

usage:

python bigfix_client_msi_clientsettings.py --input_msi <input_msi_path> --client_settings <client_settings_path>
"""

import argparse
import os
import shutil
import sys

# pip install pywin32
# python -m win32com.client.makepy -i "Windows Installer Object Library"
# net start msiserver
import win32com.client


def msi_property_edit(msi_path, property_name, new_value):
    """
    Docstring for msi_property_edit

    :param msi_path: Path to the MSI file
    :param property_name: Name of the property to update
    :param new_value: New value for the property
    """
    # Initialize the Windows Installer Object
    installer = win32com.client.Dispatch("WindowsInstaller.Installer")

    # Open the database (2 = msiOpenDatabaseModeTransact)
    db = installer.OpenDatabase(msi_path, 2)

    # Execute a SQL Update query
    view = db.OpenView(
        f"UPDATE `Property` SET `Value` = '{new_value}' WHERE `Property` = '{property_name}'"
    )
    view.Execute()

    # Commit changes and close
    db.Commit()
    print(f"Updated {property_name} to {new_value}")


def msi_update_registry_bigfix_clientsettings(msi_path, setting_name, setting_value, component="BESClient.exe"):
    """
    Inserts BigFix configuration registry keys into a specific MSI file.
    """
    # Initialize the Windows Installer Object
    installer = win32com.client.Dispatch("WindowsInstaller.Installer")

    # Open the database (2 = msiOpenDatabaseModeTransact)
    db = installer.OpenDatabase(msi_path, 2)

    # Prepare the SQL Insert query
    view = db.OpenView(
        "INSERT INTO `Registry` (`Registry`, `Root`, `Key`, `Name`, `Value`, `Component_`) "
        "VALUES (?, ?, ?, ?, ?, ?)"
    )

    # Define registry parameters
    registry_id = f"{setting_name}"  # Unique ID for the registry entry
    root = 2  # HKEY_LOCAL_MACHINE
    # SOFTWARE\BigFix\EnterpriseClient\Settings\Client
    key = r"SOFTWARE\\BigFix\\EnterpriseClient\\Settings\\Client\\" + setting_name
    name = setting_name
    value = setting_value
    # component = "BESClient.exe"  # Assuming a component named BESClient.exe exists

    # Execute the insert
    view.Execute((registry_id, root, key, name, value, component))

    # Commit changes and close
    db.Commit()
    print(f"Inserted registry setting {setting_name} with value {setting_value}")


def msi_get_components(msi_path):
    """
    Docstring for msi_get_components

    :param msi_path: Path to the MSI file
    :return: List of component names in the MSI

    This DOES NOT WORK!
    """
    # win32com.client.gencache.EnsureDispatch("WindowsInstaller.Installer")
    installer = win32com.client.Dispatch(
        "WindowsInstaller.Installer"
    )

    db = installer.OpenDatabase(msi_path, 0)  # Read-only
    view = db.OpenView("SELECT `Component` FROM `Component`")
    view.Execute()

    components = []

    record = view.Fetch()
    while record:
        components.append(record.StringData(1))  # MSI is 1-based
        record = view.Fetch()

    view.Close()
    db.Close()
    return components


def clientsettings_from_file(settings_path):
    """
    Docstring for clientsettings_from_file

    :param settings_path: Path to the clientsettings.cfg file
    :return: Dictionary of client settings
    """
    settings = {}
    with open(settings_path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#"):
                key, _, value = line.partition("=")
                settings[key.strip()] = value.strip()
    return settings


def main():
    """Execution starts here"""
    print("bigfix_client_msi_clientsettings.py main()")

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--input_msi", type=str, required=True, help="Path to input MSI file."
    )
    parser.add_argument(
        "--client_settings",
        type=str,
        required=True,
        help="Path to client settings file.",
    )
    args = parser.parse_args()

    input_msi_path = args.input_msi
    client_settings_path = args.client_settings

    if not os.path.isfile(input_msi_path):
        print(f"Input MSI file '{input_msi_path}' does not exist.")
        return

    if not os.path.isfile(client_settings_path):
        print(f"Client settings file '{client_settings_path}' does not exist.")
        return

    output_msi = os.path.splitext(input_msi_path)[0] + "_modified.msi"

    # delete output MSI if it already exists
    if os.path.isfile(output_msi):
        os.remove(output_msi)

    settings = clientsettings_from_file(client_settings_path)
    print("Client settings to apply:", settings)

    shutil.copyfile(input_msi_path, output_msi)

    # print("Components in MSI:", msi_get_components(output_msi))

    # edit the MSI registry entries based on settings
    for setting_name, setting_value in settings.items():
        msi_update_registry_bigfix_clientsettings(
            output_msi, setting_name, setting_value
        )

    print(f"Modified MSI saved as '{output_msi}'.")


if __name__ == "__main__":
    print("This is untested!")
    sys.exit(1)
    main()
