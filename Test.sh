#!/bin/bash

#================================================================
#   SYSTEM      : Linux
#   DESCRIPTION : Linux 系统维护和优化多合一工具脚本
#   AUTHOR      : Gemini
#   CREATED     : 2025-07-16
#================================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查是否以root权限运行
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}错误：此脚本必须以root权限运行！${NC}" 
   echo -e "请尝试使用 'sudo ./toolkit.sh' 命令运行。"
   exit 1
fi

# 功能1: 显示系统信息
function show_system_info() {
    echo -e "${BLUE}==============================================================${NC}"
    echo -e "${GREEN}                        系统信息概览                          ${NC}"
    echo -e "${BLUE}==============================================================${NC}"
    
    # 操作系统
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo -e "${YELLOW}操作系统       :${NC} $PRETTY_NAME"
    elif [ -f /etc/redhat-release ]; then
        echo -e "${YELLOW}操作系统       :${NC} `cat /etc/redhat-release`"
    else
        echo -e "${YELLOW}操作系统       :${NC} `uname -s`"
    fi

    # 内核版本
    echo -e "${YELLOW}内核版本       :${NC} `uname -r`"
    
    # CPU 信息
    echo -e "${YELLOW}CPU型号        :${NC} `lscpu | grep 'Model name' | cut -d: -f2- | sed 's/^[ \t]*//'`"
    echo -e "${YELLOW}CPU核心数      :${NC} `lscpu | grep '^CPU(s):' | awk '{print $2}'`"
    
    # 内存使用
    mem_total=$(free -h | awk '/^Mem:/ {print $2}')
    mem_used=$(free -h | awk '/^Mem:/ {print $3}')
    mem_percent=$(free -m | awk '/^Mem:/ {printf "%.2f%%", $3/$2*100}')
    echo -e "${YELLOW}内存           :${NC} ${mem_used} / ${mem_total} (${mem_percent})"

    # 硬盘使用
    echo -e "${YELLOW}硬盘使用       :${NC}"
    df -h | awk '$NF=="/"{printf "  - 系统根目录: %s / %s (%s)\n", $3, $2, $5}'
    
    # 系统运行时间
    echo -e "${YELLOW}系统运行时间   :${NC} `uptime -p | cut -d' ' -f2-`"
    
    # IP地址
    echo -e "${YELLOW}IP地址         :${NC} `hostname -I | awk '{print $1}'`"
    
    echo -e "${BLUE}==============================================================${NC}"
    read -p "按任意键返回主菜单..."
}

# 功能2: 更新与清理系统
function update_and_clean() {
    echo -e "${BLUE}开始更新和清理系统...${NC}"
    
    if command -v apt-get > /dev/null; then
        # 基于 Debian/Ubuntu 的系统
        echo -e "${GREEN}检测到 APT 包管理器 (Debian/Ubuntu)...${NC}"
        apt-get update -y
        echo -e "${GREEN}正在升级软件包...${NC}"
        apt-get upgrade -y
        echo -e "${GREEN}正在清理无用的软件包...${NC}"
        apt-get autoremove -y
        apt-get clean
        
    elif command -v dnf > /dev/null; then
        # 基于 RHEL/CentOS 8+ 的系统
        echo -e "${GREEN}检测到 DNF 包管理器 (CentOS/RHEL 8+)...${NC}"
        dnf update -y
        echo -e "${GREEN}正在清理无用的软件包...${NC}"
        dnf autoremove -y
        dnf clean all
        
    elif command -v yum > /dev/null; then
        # 基于 RHEL/CentOS 7 的系统
        echo -e "${GREEN}检测到 YUM 包管理器 (CentOS/RHEL 7)...${NC}"
        yum update -y
        echo -e "${GREEN}正在清理无用的软件包...${NC}"
        yum autoremove -y
        yum clean all
        
    else
        echo -e "${RED}错误：未检测到支持的包管理器 (apt, dnf, yum)！${NC}"
        return 1
    fi
    
    echo -e "${GREEN}系统更新和清理完成！${NC}"
    read -p "按任意键返回主菜单..."
}

# 功能3: 开启BBR
function enable_bbr() {
    echo -e "${BLUE}开始配置BBR加速...${NC}"
    
    # 1. 检查内核版本
    kernel_version=$(uname -r | cut -d- -f1)
    required_version="4.9"
    
    if [ "$(printf '%s\n' "$required_version" "$kernel_version" | sort -V | head -n1)" != "$required_version" ]; then
        echo -e "${RED}错误：您的内核版本 (${kernel_version}) 过低。${NC}"
        echo -e "${YELLOW}BBR 需要 Linux 内核版本 4.9 或更高。请先升级内核。${NC}"
        read -p "按任意键返回主菜单..."
        return 1
    fi
    echo -e "${GREEN}内核版本 ${kernel_version}，满足要求。${NC}"

    # 2. 检查并修改 sysctl.conf
    if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    fi
    
    if ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    fi
    
    # 3. 应用配置
    echo -e "${GREEN}正在应用配置...${NC}"
    sysctl -p > /dev/null 2>&1
    
    # 4. 验证结果
    current_congestion_control=$(sysctl -n net.ipv4.tcp_congestion_control)
    if [ "$current_congestion_control" == "bbr" ]; then
        echo -e "${GREEN}成功！BBR已开启。${NC}"
        echo -e "当前TCP拥塞控制算法: ${YELLOW}${current_congestion_control}${NC}"
    else
        echo -e "${RED}错误：BBR开启失败。${NC}"
        echo -e "请检查 /etc/sysctl.conf 文件中的配置是否正确。"
    fi
    
    read -p "按任意键返回主菜单..."
}

# 功能4: 系统调优
function tune_system() {
    echo -e "${BLUE}开始进行系统内核和网络调优...${NC}"
    
    cat > /etc/sysctl.d/99-tuning.conf << EOF
# 系统文件描述符限制
fs.file-max = 1000000
fs.nr_open = 1000000

# TCP/IP 网络栈优化
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 65535

# 内存相关
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
vm.swappiness = 10

# TCP 连接优化
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 15

# 开启 TIME-WAIT 套接字重用，对于作为客户端的连接有益
net.ipv4.tcp_tw_reuse = 1

# 开启SYN Cookies，防止SYN洪水攻击
net.ipv4.tcp_syncookies = 1

# 关闭TCP时间戳（在某些NAT环境下可能导致问题，按需开启）
# net.ipv4.tcp_timestamps = 0
EOF

    # 应用配置
    sysctl --system > /dev/null 2>&1
    
    # 修改limits.conf
    if ! grep -q "* soft nofile 1000000" /etc/security/limits.conf; then
        echo "* soft nofile 1000000" >> /etc/security/limits.conf
    fi
    if ! grep -q "* hard nofile 1000000" /etc/security/limits.conf; then
        echo "* hard nofile 1000000" >> /etc/security/limits.conf
    fi
    
    echo -e "${GREEN}系统调优完成！${NC}"
    echo -e "${YELLOW}注意：文件描述符限制 (nofile) 的更改需要重新登录或重启系统才能对所有进程生效。${NC}"
    read -p "按任意键返回主菜单..."
}


# 主菜单
function main_menu() {
    while true; do
        clear
        echo -e "${BLUE}==============================================================${NC}"
        echo -e "${GREEN}           Linux 系统维护和优化脚本 (By Gemini)           ${NC}"
        echo -e "${BLUE}==============================================================${NC}"
        echo -e " ${YELLOW}1.${NC} 显示系统信息"
        echo -e " ${YELLOW}2.${NC} 更新与清理系统"
        echo -e " ${YELLOW}3.${NC} 开启BBR加速"
        echo -e " ${YELLOW}4.${NC} 内核与网络调优"
        echo -e " ${YELLOW}0.${NC} 退出脚本"
        echo -e "${BLUE}==============================================================${NC}"
        read -p "请输入您的选择 [0-4]: " choice
        
        case $choice in
            1)
                show_system_info
                ;;
            2)
                update_and_clean
                ;;
            3)
                enable_bbr
                ;;
            4)
                tune_system
                ;;
            0)
                echo -e "${GREEN}感谢使用，再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效输入，请输入 0-4 之间的数字。${NC}"
                sleep 2
                ;;
        esac
    done
}

# 脚本入口
main_menu
