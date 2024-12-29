#!/bin/bash

# 检查用户输入的选项
while getopts ":h" option; do
  case $option in
    h)
      echo "Usage: $0 [-h] [--info|--update]"
      echo "Options:"
      echo "  -h, --help      Show this help message and exit"
      echo "  --info          Display system information"
      echo "  --update        Update the system"
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# 查看系统信息
if [[ $* == *--info* ]]; then
  echo "System Information:"
  echo "Hostname: $(hostname)"
  echo "Kernel Version: $(uname -r)"
  echo "Operating System: $(cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f 2)"
  echo "CPU Information: $(lscpu | grep 'Model name' | cut -d ':' -f 2 | tr -d ' ')"
  echo "Memory Information: $(free -h | grep 'Mem:' | awk '{print $2}')"
fi

# 进行系统更新
if [[ $* == *--update* ]]; then
  echo "Updating the system..."
  sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get autoremove -y
fi
