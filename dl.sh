#!/bin/bash
# HUTB 下载器启动脚本。
#
# 每次运行都会重新下载最新的 hutb_downloader，而不是“文件已存在就直接执行”。
# 这样可以避免旧版下载器一直残留在本地，继续报已经修复的问题（例如
# “zipfile.BadZipFile: File is not a zip file”，见 OpenHUTB/hutb#3717）。
#
# 下载过程：
#   1. curl -fL --retry 3 下载到临时文件（HTTP 404/500 直接失败）；
#   2. 校验文件大小和 ELF 文件头，防止把错误页面或半截文件当成程序执行；
#   3. 校验通过后原子覆盖 hutb_downloader；任何一步失败都不会执行旧文件。
#
# 可用环境变量：
#   HUTB_DOWNLOADER_URL        覆盖下载地址（用于镜像或测试）
#   HUTB_DOWNLOADER_MIN_BYTES  覆盖最小文件大小校验值

set -u

DOWNLOADER_URL="${HUTB_DOWNLOADER_URL:-https://gitee.com/OpenHUTB/sw/releases/download/up/hutb_downloader}"
# 正常下载器约 15 MB；小于 1 MB 的文件基本是错误页面或半截文件
MIN_BYTES="${HUTB_DOWNLOADER_MIN_BYTES:-1000000}"
DOWNLOADER="./hutb_downloader"

tmp_file=""
cleanup() {
    if [ -n "${tmp_file}" ] && [ -f "${tmp_file}" ]; then
        rm -f "${tmp_file}"
    fi
}
trap cleanup EXIT
# 被 Ctrl+C / kill 中断时也要删掉半截的临时文件
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM
trap 'cleanup; exit 129' HUP

fail() {
    echo "错误：$*" >&2
    if [ -f "${DOWNLOADER}" ]; then
        echo "没有执行本地已存在的 hutb_downloader（可能是旧版或半截文件）。" >&2
    fi
    echo "请检查网络后重新运行：./dl.sh" >&2
    exit 1
}

if [ -d "${DOWNLOADER}" ]; then
    fail "当前目录下的 hutb_downloader 是一个目录，请先删除它后重试。"
fi
command -v curl >/dev/null 2>&1 || fail "未找到 curl，请先安装 curl 后重试。"
case "${MIN_BYTES}" in
    ''|*[!0-9]*)
        fail "HUTB_DOWNLOADER_MIN_BYTES 必须是整数，当前值：${MIN_BYTES}"
        ;;
esac

# 1.原子创建：mktemp 内部使用 O_CREAT | O_EXCL，如果同名文件已存在会换一个名字重试，
# 绝不会覆盖别人已有的文件；也避免了“先判断再创建”的竞态和符号链接攻击。
# 2.失败会返回非 0：当前目录只读/无权限时，|| fail 会给出明确错误并退出。
# 3.为什么放当前目录而不是 /tmp：后面要用 mv "${tmp_file}" "./hutb_downloader" 替换正式文件。
# 同一文件系统内 mv 是原子的 rename；如果临时文件在 /tmp（不同分区），mv 就退化成“复制 + 删除”，
# 不再是原子操作，也没有“要么旧、要么新”的保证。
# 4.权限：mktemp 创建的文件默认是 600，所以脚本在校验通过后、mv 之前会 chmod 755，让最终文件保持可执行。
echo "正在下载最新的 hutb_downloader: ${DOWNLOADER_URL}"
tmp_file="$(mktemp "./.hutb_downloader.XXXXXX")" || fail "无法在当前目录创建临时文件。"

# Ubuntu 20.04 自带的 curl 7.68 里，--retry 不会重试传输中断
# 所以再加一层最多 3 次的重试；--speed-time/--speed-limit 防止连接卡死后无限等待。
download_ok=0
attempt=1
while [ "${attempt}" -le 3 ]; do
    curl -fL --retry 3 --connect-timeout 15 --speed-time 60 --speed-limit 1024 \
        -o "${tmp_file}" "${DOWNLOADER_URL}"
    curl_rc=$?
    if [ "${curl_rc}" -eq 0 ]; then
        download_ok=1
        break
    fi
    # 22 = HTTP 4xx/5xx（如 404），37 = 文件不存在，重试没有意义
    if [ "${curl_rc}" -eq 22 ] || [ "${curl_rc}" -eq 37 ]; then
        break
    fi
    if [ "${attempt}" -lt 3 ]; then
        echo "下载失败（curl 退出码 ${curl_rc}），2 秒后进行第 $((attempt + 1))/3 次尝试..." >&2
        sleep 2
    fi
    attempt=$((attempt + 1))
done
if [ "${download_ok}" -ne 1 ]; then
    fail "hutb_downloader 下载失败（HTTP 错误、网络中断或文件不存在）。"
fi

# wc -c：统计输入中的字节数（-c = bytes），tr -d 是“删除指定字符”
size="$(wc -c < "${tmp_file}" | tr -d '[:space:]')"
case "${size}" in
    ''|*[!0-9]*)
        fail "无法读取下载文件的大小。"
        ;;
esac
if [ "${size}" -lt "${MIN_BYTES}" ]; then
    fail "下载的文件只有 ${size} 字节，可能是不完整的文件或错误页面。"
fi

# PyInstaller 打包的 Linux 下载器是 ELF 可执行文件（文件头 7f 45 4c 46）。
# od	octal dump，把文件内容按指定格式打印出来
# -A n（写作 -An）	不显示地址列（address none），只输出字节值
# -t x1（写作 -tx1）	输出类型为十六进制（hex），每个单元 1 字节
# -N4	只读前 4 个字节（-N 指定读取字节数）
magic="$(od -An -tx1 -N4 "${tmp_file}" | tr -d '[:space:]')"
if [ "${magic}" != "7f454c46" ]; then
    fail "下载的文件不是 Linux 可执行程序（文件头: ${magic:-空}）。"
fi

# 与旧脚本 curl 下载后的权限保持一致（600 -> 755），避免继承 mktemp 的 600
chmod 755 "${tmp_file}" || fail "无法为 hutb_downloader 添加可执行权限。"
mv -f "${tmp_file}" "${DOWNLOADER}" || fail "无法覆盖 hutb_downloader。"
tmp_file=""  # 已成功移动，不需要清理

if [ -z "${1:-}" ]; then
    echo "No arguments provided."
    ./hutb_downloader
else
    echo "Arguments provided: $*"
    ./hutb_downloader "$@"
fi
exit $?
