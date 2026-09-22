echo off

if not exist "hutb_downloader.exe" (
    echo "hutb_downloader.exe not found, downloading from remote repository..."
    curl -L -o hutb_downloader.exe https://gitee.com/OpenHUTB/sw/releases/download/up/hutb_downloader.exe
)

if "%1"=="" (
    echo "No arguments provided."
    hutb_downloader.exe
) else (
    echo "Arguments provided: %*"
    hutb_downloader.exe %*
)