#!/bin/bash
# 一个用于下载 GitHub 仓库并复制 dyson_local 文件夹的脚本

# 启用错误处理选项
set -euo pipefail

# 定义错误处理函数
error_exit () {
  echo "错误: $1"
  exit 1
}

# 定义清理函数
cleanup () {
  rm -rf "${tempfiles[@]}"
}

# 捕捉信号和退出事件
trap cleanup EXIT
trap 'error_exit ${LINENO}' ERR

# 创建临时目录 tmpha
temp_dir=$(mktemp -d -t tmpha.XXXXXX) || error_exit "无法创建临时目录"
tempfiles+=("$temp_dir")
echo "创建临时目录: $temp_dir"

# 下载 GitHub 仓库 shenxn/ha-dyson 到临时目录
wget -O "$temp_dir"/ha-dyson.zip https://github.com/shenxn/ha-dyson/archive/refs/heads/main.zip || error_exit "无法下载 GitHub 仓库"

# 检查是否是压缩文件
if file "$temp_dir"/ha-dyson.zip | grep -q "Zip archive data"; then
  # 是压缩文件，检查是否安装 unzip 命令
  if ! command -v unzip &> /dev/null; then
    error_exit "unzip 命令没有安装"
  fi
  # 解压文件到临时目录
  unzip "$temp_dir"/ha-dyson.zip -d "$temp_dir" || error_exit "无法解压文件"
  # 查找 dyson_local 文件夹，限制深度为 2
  dyson_local=$(find "$temp_dir" -maxdepth 2 -type d -name dyson_local) || error_exit "无法查找 dyson_local 文件夹"
else
  # 不是压缩文件，直接查找 dyson_local 文件夹，限制深度为 2
  dyson_local=$(find "$temp_dir" -maxdepth 2 -type d -name dyson_local) || error_exit "无法查找 dyson_local 文件夹"
fi

# 确认 dyson_local 文件夹里面包含 manifest.json 文件
if [ ! -f "$dyson_local"/manifest.json ]; then
  error_exit "dyson_local 文件夹里面没有 manifest.json 文件"
fi

# 扫描本地系统存在 custom_components 文件夹的路径，并给出数字编号的选择项
echo "请选择要复制 dyson_local 文件夹的路径："
select dest in $(find / -type d -name custom_components); do
  if [ ! -z "$dest" ]; then
    # 复制 dyson_local 文件夹到指定的路径
    cp -r "$dyson_local" "$dest" || error_exit "无法复制 dyson_local 文件夹"
    echo "已复制 dyson_local 文件夹到 $dest"
    break
  else
    echo "无效的选择，请重新选择"
  fi
done

# 提示要重启 ha
echo "请重启 ha"


