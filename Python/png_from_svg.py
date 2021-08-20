
import os
from ctypes.util import find_library

# cario alternative?
#from svglib.svglib import svg2rlg
#from reportlab.graphics import renderPDF, renderPM

# https://github.com/Kozea/WeasyPrint/issues/1279
# https://igraph.discourse.group/t/problem-installing-cairo-library/156
# https://packages.msys2.org/package/mingw-w64-x86_64-cairo
# https://newbedev.com/python-oserror-cannot-load-library-libcairo-so-2
# cario depends on gtk




# def set_dll_search_path():
#     # Python 3.8 no longer searches for DLLs in PATH, so we have to add
#     # everything in PATH manually. Note that unlike PATH add_dll_directory
#     # has no defined order, so if there are two cairo DLLs in PATH we
#     # might get a random one.
#     if os.name != "nt" or not hasattr(os, "add_dll_directory"):
#         return
#     for p in os.environ.get("PATH", "").split(os.pathsep):
#         try:
#             os.add_dll_directory(p)
#         except OSError:
#             pass




def main():
    print("main():")
    # https://stackoverflow.com/questions/46265677/get-cairosvg-working-in-windows
    os.environ['PATH'] += r';/tmp/libcario'
    #set_dll_search_path()
    #libpath = find_library("libcairo")
    #print(libpath)
    # os.add_dll_directory(os.path.dirname(__file__))
    # https://man7.org/linux/man-pages/man3/dlopen.3.html
    # os.environ["LD_LIBRARY_PATH"] = os.path.dirname(__file__)
    from cairosvg import svg2png
    svg2png(url="https://raw.githubusercontent.com/jgstew/jgstew.github.io/master/images/BigFix/BigFix_logo.svg", write_to="svg2png_output.png")


if __name__ == "__main__":
    main()