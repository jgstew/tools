
strOutputDir   = ".\"
strZipFilePath = "_PATH_TO_FILE_.zip"
CreateObject( "Shell.Application" ).NameSpace( CreateObject("Scripting.FileSystemObject").GetAbsolutePathName( strOutputDir ) ).copyHere ( CreateObject( "Shell.Application" ).NameSpace( CreateObject("Scripting.FileSystemObject").GetAbsolutePathName( strZipFilePath ) ).Items() ), 1044
