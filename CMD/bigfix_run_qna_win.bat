
@ECHO OFF
SET ARGS=%*

if not exist "\Windows\Temp\bigfix_qna" (
    mkdir "\Windows\Temp\bigfix_qna"
)

if not exist "\Windows\Temp\bigfix_qna\QNA.zip" (
    curl -o "\Windows\Temp\bigfix_qna\QNA.zip" http://software.bigfix.com/download/bes/92/util/QNA9.2.5.130.zip
)

tar -xf "\Windows\Temp\bigfix_qna\QNA.zip" -C "\Windows\Temp\bigfix_qna"

if "%ARGS%"=="" (
"\Windows\Temp\bigfix_qna\QNA.exe" -showtypes
) else (
echo %ARGS% | "\Windows\Temp\bigfix_qna\QNA.exe" -showtypes
)
attrib +r "\Windows\Temp\bigfix_qna\QNA.zip"

REM Cleanup:
REM del C:\Windows\Temp\bigfix_qna\*.* /A-R /Q
