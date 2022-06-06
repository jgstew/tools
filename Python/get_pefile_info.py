import pefile

# import signify
# import windows.wintrust


def main(pathname=r"C:\Windows\explorer.exe"):
    print("main()")
    print(pathname)
    pe = pefile.PE(pathname)
    pe.print_info()
    # Example:
    """
    [StringFileInfo]
        [StringTable]
            CompanyName: Microsoft Corporation
            FileDescription: Windows Explorer
            FileVersion: 10.0.19041.1706 (WinBuild.160101.0800)
            InternalName: explorer
            LegalCopyright: ⌐ Microsoft Corporation. All rights reserved.
            OriginalFilename: EXPLORER.EXE
            ProductName: Microsoft« Windows« Operating System
            ProductVersion: 10.0.19041.1706
    """
    print(hex(pe.VS_FIXEDFILEINFO[0].Signature))
    # for fileinfo in pe.FileInfo[0]:
    #     if fileinfo.Key == "StringFileInfo":
    #         for st in fileinfo.StringTable:
    #             for entry in st.entries.items():
    #                 print("%s: %s" % (entry[0], entry[1]))


# if called directly, then run this example:
if __name__ == "__main__":
    main()
