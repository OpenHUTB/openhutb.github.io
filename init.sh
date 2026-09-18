# for all repositories
# 如果当前目录下没有 pr.sh 文件，则从远程仓库下载
if [ ! -f pr.sh ]; then
    echo "pr.sh not found, downloading from remote repository..."
    curl -O https://raw.githubusercontent.com/OpenHUTB/utils/refs/heads/master/git/pr.sh
    chmod +x pr.sh
fi

if [ ! -f serve.sh ]; then
    echo "serve.sh not found, downloading from remote repository..."
    curl -O https://raw.githubusercontent.com/OpenHUTB/template/refs/heads/master/serve.sh
    chmod +x serve.sh
fi