import icoextract

icoExtInst = icoextract.IconExtractor(r"C:\Program Files\Microsoft VS Code\Code.exe")

icoExtInst.export_icon("vscode.png")
