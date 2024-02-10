"""
A simple script that echos args to stdout and to a log file
"""

import sys


def main():
    """Execution starts here"""
    print("main()")

    print(sys.argv)

    with open("args_log.log", "w") as f:
        f.write(str(sys.argv))

    return 0


if __name__ == "__main__":
    sys.exit(main())
