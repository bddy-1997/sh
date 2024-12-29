#!/bin/bash

# Function to display system information
function display_system_info() {
    echo "System Information:"
    uname -a
    lsb_release -a
    echo
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
echo "选择要执行的操作："
echo "1. 显示系统信息"
echo "2. 更新系统和软件包并清理系统"
read choice

case $choice in
    1)
        display_system_info
        ;;
    2)
        if [[ $(uname -s) == "Linux" ]]; then
            update_system
            clean_system
        else
            echo "Unsupported operating system."
        fi
        ;;
    *)
        echo "无效的选择"
        ;;
esac
