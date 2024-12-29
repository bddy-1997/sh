#!/bin/bash

# Function to display system information
function display_system_info() {
    echo "系统信息查询"
    echo "-------------"
    echo "主机名:       $(hostname)"
    echo "系统版本:     $(lsb_release -d | cut -f2)"
    echo "Linux版本:    $(uname -r)"
    echo "-------------"
    echo "CPU架构:      $(uname -m)"
    echo "CPU型号:      $(grep 'model name' /proc/cpuinfo | head -n1 | cut -d':' -f2 | sed 's/^[ \t]*//')"
    echo "CPU核心数:    $(grep -c 'processor' /proc/cpuinfo)"
    echo "CPU频率:      $(grep 'cpu MHz' /proc/cpuinfo | head -n1 | cut -d':' -f2 | sed 's/^[ \t]*//') GHz"
    echo "-------------"
    echo "CPU占用:      $(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')%"
    echo "系统负载:     $(uptime | awk '{print $10,$11,$12}')"
    echo "物理内存:     $(free -m | awk 'NR==2{printf "%.2f/%.2f MB (%.2f%%)\n", $3,$2,$3*100/$2 }')"
    echo "虚拟内存:     $(free -m | awk 'NR==3{printf "%.2f/%.2f MB (%.2f%%)\n", $3,$2,$3*100/$2 }')"
    echo "硬盘占用:     $(df -h | awk '$NF=="/"{printf "%s/%s (%s)\n", $3,$2,$5}')"
    echo "-------------"
    echo "总接收:       $(ifconfig | grep 'RX packets' | awk '{print $5}')"
    echo "总发送:       $(ifconfig | grep 'TX packets' | awk '{print $5}')"
    echo "-------------"
    echo "网络算法:     $(sysctl net.ipv4.tcp_congestion_control | cut -d'=' -f2)"
    echo "-------------"
    echo "运营商:       $(whois $(dig +short myip.opendns.com @resolver1.opendns.com) | grep -i 'OrgName' | cut -d':' -f2 | sed 's/^[ \t]*//')"
    echo "IPv4地址:     $(dig +short myip.opendns.com @resolver1.opendns.com)"
    echo "DNS地址:      $(cat /etc/resolv.conf | grep 'nameserver' | awk '{print $2}' | head -n1)"
    echo "地理位置:     $(curl -s ipinfo.io | grep 'loc' | cut -d':' -f2 | sed 's/^[ \t]*//')"
    echo "系统时间:     $(date)"
    echo "-------------"
    echo "运行时长:     $(uptime -p)"
    echo "按任意键继续..."
    read -n 1 -s
}

# Function to update the system
function update_system() {
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get upgrade -y
    elif command -v yum &> /dev/null; then
        sudo yum update -y
    else
        echo "Unsupported package manager."
    fi
}

# Function to clean the system
function clean_system() {
    if command -v apt-get &> /dev/null; then
        sudo apt-get autoclean
        sudo apt-get autoremove -y
    elif command -v yum &> /dev/null; then
        sudo package-cleanup --oldkernels --count=1
    else
        echo "Unsupported package manager."
    fi
}

# Main script
while true; do
    clear
    echo "选择要执行的操作："
    echo "1. 显示系统信息"
    echo "2. 更新系统和软件包并清理系统"
    echo "0. 退出"
    read choice

    case $choice in
        1)
            display_system_info
            ;;
        2)
            if [[ $(uname -s) == "Linux" ]]; then
                update_system
                clean_system
                echo "更新系统和软件包并清理系统的工作已完成，按任意键继续..."
                read -n 1 -s
            else
                echo "Unsupported operating system."
            fi
            ;;
        0)
            exit 0
            ;;
        *)
            echo "无效的选择"
            echo "按任意键继续..."
            read -n 1 -s
            ;;
    esac
done
