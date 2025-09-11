"""
This is Windows only

requires: `pip install -U pywin32`
"""

# https://stackoverflow.com/questions/580924/how-to-access-a-files-properties-on-windows


import win32api


def getFileProperties(fname):
    """
    Read all properties of the given file return them as a dictionary.
    """
    propNames = (
        "Comments",
        "InternalName",
        "ProductName",
        "CompanyName",
        "LegalCopyright",
        "ProductVersion",
        "FileDescription",
        "LegalTrademarks",
        "PrivateBuild",
        "FileVersion",
        "OriginalFilename",
        "SpecialBuild",
    )

    props = {"FixedFileInfo": None, "StringFileInfo": None, "FileVersion": None}

    try:
        # backslash as param returns dictionary of numeric info corresponding to VS_FIXEDFILEINFO struct
        fixedInfo = win32api.GetFileVersionInfo(fname, "\\")
        props["FixedFileInfo"] = fixedInfo
        props["FileVersion"] = "%d.%d.%d.%d" % (
            fixedInfo["FileVersionMS"] / 65536,
            fixedInfo["FileVersionMS"] % 65536,
            fixedInfo["FileVersionLS"] / 65536,
            fixedInfo["FileVersionLS"] % 65536,
        )

        # \VarFileInfo\Translation returns list of available (language, codepage)
        # pairs that can be used to retrieve string info. We are using only the first pair.
        lang, codepage = win32api.GetFileVersionInfo(
            fname, "\\VarFileInfo\\Translation"
        )[0]

        # any other must be of the form \StringfileInfo\%04X%04X\parm_name, middle
        # two are language/codepage pair returned from above

        strInfo = {}
        for propName in propNames:
            strInfoPath = "\\StringFileInfo\\{:04X}{:04X}\\{}".format(
                lang, codepage, propName
            )
            # print(strInfo)
            strInfo[propName] = win32api.GetFileVersionInfo(fname, strInfoPath)

        props["StringFileInfo"] = strInfo
    except Exception as e:
        print("Error:", e)

    return props


def main():
    filepath = r"C:\Program Files\7-Zip\7z.exe"
    pe_info_dict = getFileProperties(filepath)

    print(pe_info_dict)
    print(pe_info_dict["FileVersion"])


if __name__ == "__main__":
    main()
