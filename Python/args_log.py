"""
A simple script that echos args to stdout and to a log file

pyinstaller --onefile args_log.py
"""

import os
import sys


def main():
    """Execution starts here"""
    print("main()")

    log_folder = os.path.abspath(os.getcwd())

    log_file_path = log_folder + "/args_log.log"

    print(f"Log File Path: {log_file_path}")

    print(sys.argv)

    with open(log_file_path, "a", encoding="utf-8") as f:
        f.write(str(sys.argv) + "\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
