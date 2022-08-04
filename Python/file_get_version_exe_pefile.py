"""
Get info from pe files (EXE, DLL)

This is cross platform

requires: `pip install -U pefile`

From:
- https://stackoverflow.com/questions/580924/how-to-access-a-files-properties-on-windows
- https://stackoverflow.com/a/58241294/861745
"""


import pefile


def dump_info_pefile(filepath):
    pe = pefile.PE(filepath)

    pe_info_dict = {}

    if hasattr(pe, "VS_VERSIONINFO"):
        for idx in range(len(pe.VS_VERSIONINFO)):
            if hasattr(pe, "FileInfo") and len(pe.FileInfo) > idx:
                for entry in pe.FileInfo[idx]:
                    if hasattr(entry, "StringTable"):
                        for st_entry in entry.StringTable:
                            for str_entry in sorted(list(st_entry.entries.items())):
                                pe_info_dict[
                                    str_entry[0].decode("utf-8", "backslashreplace")
                                ] = str_entry[1].decode("utf-8", "backslashreplace")
                                # print('{0}: {1}'.format(
                                #     str_entry[0].decode('utf-8', 'backslashreplace'),
                                #     str_entry[1].decode('utf-8', 'backslashreplace')))
    return pe_info_dict


def main():
    filepath = r"C:\Program Files\7-Zip\7z.exe"
    pe_info_dict = dump_info_pefile(filepath)

    print(pe_info_dict)
    print(pe_info_dict["FileVersion"])
    print(pe_info_dict["ProductVersion"])
    print(pe_info_dict["ProductName"])


if __name__ == "__main__":
    main()
