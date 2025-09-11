// 2>nul||@goto :batch
/*
:batch
@echo off
setlocal

:: find csc.exe
set "csc="
for /r "%SystemRoot%\Microsoft.NET\Framework\" %%# in ("*csc.exe") do  set "csc=%%#"

if not exist "%csc%" (
   echo no .net framework installed
   exit /b 10
)

if not exist "%~n0.exe" (
   call %csc% /nologo /r:"Microsoft.VisualBasic.dll" /out:"%~n0.exe" "%~dpsfnx0" || (
      exit /b %errorlevel%
   )
)
%~n0.exe %*
endlocal & exit /b %errorlevel%

*/

// reference
// https://stackoverflow.com/questions/462270/get-file-icon-used-by-shell
// https://www.bigfix.me/fixlet/details/21898
// https://gallery.technet.microsoft.com/scriptcenter/eeff544a-f690-4f6b-a586-11eea6fc5eb8

using System; // required by Console.WriteLine
using System.Drawing;


class Class1
{
    public static void Main( string[] args )
    {
        var filePath =  @"setup.exe";
        if (args.Length != 0)
        {
            filePath =  @args[0];
        }
        var theIcon = IconFromFilePath(filePath);

        if (theIcon != null)
        {
            // Save it to disk, or do whatever you want with it.
            using (var stream = new System.IO.FileStream(@filePath+".ico", System.IO.FileMode.CreateNew))
            {
                theIcon.Save(stream);
            }
        }
    }

    public static Icon IconFromFilePath(string filePath)
    {
        var result = (Icon)null;

        try
        {
            result = Icon.ExtractAssociatedIcon(filePath);
        }
        catch (System.Exception)
        {
            // swallow and return nothing. You could supply a default Icon here as well
            Console.WriteLine("ERROR: No Icon Found   TODO: Provide Default Icon?");
        }

        return result;
    }
}
