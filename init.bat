@echo off

if not exist pr.bat (
    echo Downloading pr.bat...
    curl -O --ssl-no-revoke https://raw.githubusercontent.com/OpenHUTB/utils/refs/heads/master/git/pr.bat
)

if not exist serve.bat (
    echo Downloading serve.bat...
    curl -O --ssl-no-revoke https://raw.githubusercontent.com/OpenHUTB/template/refs/heads/master/serve.bat
)


