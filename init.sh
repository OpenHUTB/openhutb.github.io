# !/bin/bash
# 对所有 OpenHUTB 都适用的脚本
# 使用方法：
#     curl -O https://openhutb.github.io/init.sh
# 下载测试 Pull Request 脚本 pr.sh
if [ ! -f pr.sh ]; then
    echo "pr.sh not found, downloading from remote repository..."
    curl -O https://raw.githubusercontent.com/OpenHUTB/utils/refs/heads/master/git/pr.sh
    chmod +x pr.sh
fi

# 下载启动 mkdocs serve 的脚本
if [ ! -f serve.sh ]; then
    echo "serve.sh not found, downloading from remote repository..."
    curl -O https://raw.githubusercontent.com/OpenHUTB/template/refs/heads/master/serve.sh
    chmod +x serve.sh
fi