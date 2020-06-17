
def get_filename_from_pathname(pathnames):
    # if arg is a not a list, make it so
    # https://stackoverflow.com/a/922800/861745
    if not isinstance(pathnames, (list, tuple)):
        pathnames = [pathnames]
    
    for pathname in pathnames:
        # print( pathname )
        print( pathname.replace('\\','/').replace('}','/').split('/')[-1] )

def main():
    str_pathname = "path blah/ path \ this}file name from string.txt"
    array_pathnames = [
        "",
        "file name from array.txt",
        "path blah/ path \ this}file name.txt",
        "path blah/ path \ this}file.txt"
    ]
    get_filename_from_pathname(str_pathname)
    get_filename_from_pathname(array_pathnames)


# if called directly, then run this example:
if __name__ == '__main__':
    main()

# https://forum.bigfix.com/t/get-filename-from-arbitrary-pathnames/34616
