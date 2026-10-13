#!/bin/bash

if [ ! -f "hutb_downloader" ]; then
    echo "hutb_downloader not found, downloading from remote repository..."
    curl -L -o hutb_downloader https://gitee.com/OpenHUTB/sw/releases/download/up/hutb_downloader
fi

if [ -z "$1" ]; then
    echo "No arguments provided."
    chmod +x hutb_downloader
    ./hutb_downloader
else
    echo "Arguments provided: $*"
    chmod +x hutb_downloader
    ./hutb_downloader "$@"
fi
