
REM query the DNS `TXT` record of `google.com` with a 15 second time out
nslookup -q=TXT -timeout=15 google.com

REM https://blogs.technet.microsoft.com/rmilne/2015/09/11/how-to-use-nslookup-to-check-dns-txt-record/
REM http://www.windowscommandline.com/nslookup/
REM https://www.owasp.org/index.php/OWASP_File_Hash_Repository
REM http://www.ghacks.net/2010/02/16/whitelist-hash-database-frontend/
REM https://github.com/rjhansen/nsrllookup
