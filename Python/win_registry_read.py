"""
Read Windows Registry Key Value
"""

try:
    import winreg
except (ImportError, ModuleNotFoundError) as e:
    raise ImportError(
        "This script requires the 'winreg' module, which is only available on Windows."
    ) from e


def read_registry_value(hive, subkey, value_name):
    """
    Reads a value from the Windows Registry.

    Args:
        hive: The root hive (e.g., winreg.HKEY_LOCAL_MACHINE, winreg.HKEY_CURRENT_USER).
        subkey: The path to the subkey (e.g., "SOFTWARE\\Microsoft\\Windows\\CurrentVersion").
        value_name: The name of the value to read.

    Returns:
        The value data if found, otherwise None.
    """
    try:
        # Open the specified registry key
        key = winreg.OpenKey(hive, subkey, 0, winreg.KEY_READ)

        # Query the value data
        value_data, _ = winreg.QueryValueEx(key, value_name)

        # Close the key
        winreg.CloseKey(key)

        return value_data
    except FileNotFoundError:
        print(f"Registry key or value '{subkey}\\{value_name}' not found.")
        return None
    except Exception as e:
        print(f"An error occurred: {e}")
        return None


# Example usage:
reg_value = read_registry_value(
    winreg.HKEY_LOCAL_MACHINE,
    r"SOFTWARE\Wow6432Node\BigFix\Enterprise Server",
    "Version",
)

if reg_value:
    print(f"Registry Value: {reg_value}")
