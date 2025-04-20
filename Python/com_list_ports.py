"""
This script lists all available COM ports on the system along with their details.
It uses the `serial` library to access the COM ports and their properties.
Make sure to install the pyserial library if you haven't already:
  python3 -m pip install pyserial

Related:
- https://github.com/pvvx/THB2/tree/master
"""
import serial.tools.list_ports

for com in serial.tools.list_ports.comports():
    print(f"Device: {com.device}")
    print(f"Description: {com.description}")
    print(f"Hardware ID: {com.hwid}")
    print(f"Location: {com.location}")
    print(f"Manufacturer: {com.manufacturer}")
    print(f"Serial Number: {com.serial_number}")
    # print(com)
    print("-" * 40)
