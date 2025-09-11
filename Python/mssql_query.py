"""
run an MSSQL query with python

References:
- https://pypi.org/project/pymssql/
"""

import argparse
import getpass

import pymssql


def main():
    """Execution starts here"""
    print("main() start")

    parser = argparse.ArgumentParser(
        description="Provide command line arguments for server, username, db, and query"
    )
    parser.add_argument(
        "-v",
        "--verbose",
        help="Set verbose output",
        required=False,
        action="count",
        default=0,
    )
    parser.add_argument(
        "-s", "--server", help="Specify the MSSQL Server", required=True
    )
    parser.add_argument(
        "-u", "--user", help="Specify the username", required=False, default="sa"
    )
    parser.add_argument(
        "--db", help="Specify the db", required=False, default="BFEnterprise"
    )
    parser.add_argument(
        "--query",
        help="Specify the query",
        required=False,
        default="SELECT [Sitename],[Version] FROM [BFEnterprise].[dbo].[BES_SITEVERSIONS]",
    )
    # allow unknown args to be parsed instead of throwing an error:
    args, _unknown = parser.parse_known_args()

    print("Enter Password for MSSQL:")
    password = getpass.getpass()

    mssql_conn = pymssql.connect(args.server, args.user, password, args.db)
    cursor = mssql_conn.cursor(as_dict=True)

    cursor.execute(args.query)

    for row in cursor:
        print(row)

    mssql_conn.close()


# if called directly, then run this example:
if __name__ == "__main__":
    main()
