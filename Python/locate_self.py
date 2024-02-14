"""
Find the folder that invoked script or binary is in

The method is different if it is a python script vs a pyinstaller binary

python locate_self.py
pyinstaller locate_self.py
pyinstaller --onefile locate_self.py

References:
- https://pyinstaller.org/en/stable/runtime-information.html
"""

import os
import sys


def main(debug=True):
    """Execution starts here"""
    print("main()")

    if debug:
        print(f"sys.executable = {sys.executable}")
        print(f"__file__ = {__file__}")
        print(f"os.path.abspath(sys.argv[0]) = {os.path.abspath(sys.argv[0])}")
        print(f"os.getcwd() = { os.getcwd() }")

    invoke_folder = ""

    if getattr(sys, "frozen", False) and hasattr(sys, "_MEIPASS"):
        if debug:
            print("running in a PyInstaller bundle")
        invoke_folder = os.path.abspath(os.path.dirname(sys.executable))
    else:
        if debug:
            print("running in a normal Python process")
        invoke_folder = os.path.abspath(os.path.dirname(__file__))

    print(f"invoke_folder = {invoke_folder}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
