"""
Example to get input values from args or ENV variables.

Example run:

THIRD_ARG=ENVin python3 Python/args_or_env.py --first_arg ArgIn --second_arg tRue


Example output:

First arg: ArgIn
Second arg: True
Third arg: ENVin
Fourth arg: DefaultValue4
"""

import argparse
import os


def main():
    """Execution starts here"""
    print("main()")

    parser = argparse.ArgumentParser()
    parser.add_argument("--first_arg", type=str, help="First Arg.")
    parser.add_argument("--second_arg", type=bool, help="Second Arg.")
    parser.add_argument("--third_arg", type=str, help="Third Arg.")
    parser.add_argument("--fourth_arg", type=str, help="Fourth Arg.")
    args = parser.parse_args()

    # Prioritize command-line arg, then environment variable, then a default
    first_arg = args.first_arg or os.environ.get("FIRST_ARG", "DefaultValue1")
    second_arg = args.second_arg or (
        os.environ.get("SECOND_ARG", "false").lower() == "true"
    )
    third_arg = args.third_arg or os.environ.get("THIRD_ARG", "DefaultValue3")
    fourth_arg = args.fourth_arg or os.environ.get("FOURTH_ARG", "DefaultValue4")

    print(f"First arg: {first_arg}")
    print(f"Second arg: {second_arg}")
    print(f"Third arg: {third_arg}")
    print(f"Fourth arg: {fourth_arg}")


if __name__ == "__main__":
    main()
