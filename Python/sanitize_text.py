"""
Python module to sanitize text for use with file or folder names
"""
import string


def sanitize_txt(*args):
    """ Clean arbitrary text for safe file system usage."""
    valid_chars = "-_.() %s%s" % (string.ascii_letters, string.digits)

    sani_args = []
    for arg in args:
        sani_args.append(
            "".join(
                c
                for c in str(arg).replace("/", "-").replace("\\", "-")
                if c in valid_chars
            )
        )

    return tuple(sani_args)


def main():
    """default execution starts here"""
    print("main()")
    print(sanitize_txt("blah/blah\\blah??", "another\///\\.?_-string:"))


if __name__ == "__main__":
    main()
