echo off
rem 下载 OpenHUTB 模拟器和相关大文件仓库
rem 使用方法：
rem     dl.bat [参数]
rem         无参数表示下载模拟器，
rem         -r 表示下载大文件仓库

rem 如果当前目录不存在 hutb_downloader.exe，则下载该文件
if not exist "hutb_downloader.exe" (
    echo "hutb_downloader.exe not found, downloading from remote repository..."
    curl -L -o hutb_downloader.exe https://gitee.com/OpenHUTB/sw/releases/download/up/hutb_downloader.exe
)

rem 运行脚本时候没有参数
if "%1"=="" (
    echo "No arguments provided."
    hutb_downloader.exe
) else (
    rem 运行脚本时候有参数
    echo "Arguments provided: %*"
    hutb_downloader.exe %*
)