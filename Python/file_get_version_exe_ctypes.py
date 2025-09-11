"""
Get info from pe files (EXE, DLL)

This is cross platform

From:
- https://stackoverflow.com/questions/580924/how-to-access-a-files-properties-on-windows
"""

from ctypes import *


# returns the requested version information from the given file
#
# `language` should be an 8-character string combining both the language and
# codepage (such as "040904b0"); if None, the first language in the translation
# table is used instead
#
def get_version_string(filename, what, language=None):
    # VerQueryValue() returns an array of that for VarFileInfo\Translation
    #
    class LANGANDCODEPAGE(Structure):
        _fields_ = [("wLanguage", c_uint16), ("wCodePage", c_uint16)]

    wstr_file = wstring_at(filename)

    # getting the size in bytes of the file version info buffer
    size = windll.version.GetFileVersionInfoSizeW(wstr_file, None)
    if size == 0:
        raise WinError()

    buffer = create_string_buffer(size)

    # getting the file version info data
    if windll.version.GetFileVersionInfoW(wstr_file, None, size, buffer) == 0:
        raise WinError()

    # VerQueryValue() wants a pointer to a void* and DWORD; used both for
    # getting the default language (if necessary) and getting the actual data
    # below
    value = c_void_p(0)
    value_size = c_uint(0)

    if language is None:
        # file version information can contain much more than the version
        # number (copyright, application name, etc.) and these are all
        # translatable
        #
        # the following arbitrarily gets the first language and codepage from
        # the list
        ret = windll.version.VerQueryValueW(
            buffer,
            wstring_at(r"\VarFileInfo\Translation"),
            byref(value),
            byref(value_size),
        )

        if ret == 0:
            raise WinError()

        # value points to a byte inside buffer, value_size is the size in bytes
        # of that particular section

        # casting the void* to a LANGANDCODEPAGE*
        lcp = cast(value, POINTER(LANGANDCODEPAGE))

        # formatting language and codepage to something like "040904b0"
        language = f"{lcp.contents.wLanguage:04x}{lcp.contents.wCodePage:04x}"

    # getting the actual data
    res = windll.version.VerQueryValueW(
        buffer,
        wstring_at("\\StringFileInfo\\" + language + "\\" + what),
        byref(value),
        byref(value_size),
    )

    if res == 0:
        raise WinError()

    # value points to a string of value_size characters, minus one for the
    # terminating null
    return wstring_at(value.value, value_size.value - 1)


def main():
    filepath = r"C:\Program Files\7-Zip\7z.exe"
    version_str = get_version_string(filepath, "FileVersion")
    # version_str = get_version_string(filepath, "ProductVersion")
    print(version_str)


if __name__ == "__main__":
    main()
