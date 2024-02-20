"""
Read BigFix Client Settings
"""

import sys
import winreg


def read_value_from_subkey(key_path, subkey_name):
    """
    Read the value named "value" from a specified subkey under a given registry key.

    Parameters:
        key_path (str): The registry key path.
        subkey_name (str): The name of the subkey.

    Returns:
        str or None: The value of the "value" entry if found, None otherwise.
    """
    try:
        # Open the subkey
        key = winreg.OpenKey(
            winreg.HKEY_LOCAL_MACHINE,
            rf"{key_path}\{subkey_name}",
            0,
            winreg.KEY_READ | winreg.KEY_WOW64_64KEY,
        )

        # Read the value named "value"
        value, _ = winreg.QueryValueEx(key, "value")

        # Close the subkey
        winreg.CloseKey(key)

        return value
    except FileNotFoundError:
        print(f"Subkey '{subkey_name}' not found under '{key_path}'.")
    except Exception as e:
        print(f"Error reading value from subkey '{subkey_name}':", e)
    return None


def get_subkeys(key_path):
    """
    Get a list of subkeys under a given registry key.

    Parameters:
        key_path (str): The registry key path.

    Returns:
        list: A list containing the names of all subkeys.
    """
    subkeys = []
    try:
        # Open the registry key
        key = winreg.OpenKey(
            winreg.HKEY_LOCAL_MACHINE,
            key_path,
            0,
            winreg.KEY_READ | winreg.KEY_WOW64_64KEY,
        )

        # Enumerate subkeys
        index = 0
        while True:
            try:
                subkey = winreg.EnumKey(key, index)
                subkeys.append(subkey)
                index += 1
            except OSError:
                # End of enumeration
                break

        # Close the registry key
        winreg.CloseKey(key)
    except FileNotFoundError:
        print(f"Registry key '{key_path}' not found.")
    except BaseException as e:
        print("Error reading registry key:", e)

    return subkeys


def main():
    """Execution starts here"""
    print("main()")

    # Specify the possible registry key paths
    key_paths = [
        r"SOFTWARE\WOW6432Node\BigFix\EnterpriseClient\Settings\Client",
        r"SOFTWARE\BigFix\EnterpriseClient\Settings\Client",
    ]

    # Iterate over each possible registry key path
    for key_path in key_paths:
        subkeys = get_subkeys(key_path)
        if subkeys:
            print(f"Reading values from subkeys under {key_path}:")
            for subkey in subkeys:
                value = read_value_from_subkey(key_path, subkey)
                if value is not None:
                    print(f"Subkey: {subkey}, Value: {value}")
            break
    else:
        print("No valid registry key found.")


if __name__ == "__main__":
    sys.exit(main())
