# Linux Security Tools Installer 🛡️

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![GitHub Release](https://img.shields.io/badge/Release-v1.0-orange.svg) 
![Platform](https://img.shields.io/badge/OS-Linux-green.svg)

A robust bash script for automated installation of essential security tools across multiple Linux distributions.

## 📦 Included Tools

| Tool | Purpose | Version |
|------|---------|---------|
| Python3 | Scripting language | Latest |
| Go (Golang) | Tool compilation | Latest |
| Docker | Containerization | Latest |
| Subfinder | Subdomain discovery | v2.x |
| httpx | HTTP toolkit | Latest |
| Nuclei | Vulnerability scanning | v2.x |
| Naabu | Port scanning | v2.x |
| Nmap | Network exploration | Latest |

## 🌟 Features

- **Multi-distro support**: Works on Debian, Ubuntu, RHEL, CentOS, Arch, and derivatives
- **Automatic dependency handling**: Installs all required dependencies
- **Docker ready**: Configures Docker with proper user permissions
- **Go environment setup**: Automatic GOPATH configuration
- **Verification system**: Validates all installations

### Prerequisites
- Linux OS (see supported distributions below)
- sudo/root privileges
- Internet connection


### One-line Install
```bash
wget https://raw.githubusercontent.com/AhSec0x1/linux-security-tools/main/linux-security-tools-installer.sh && sudo chmod +x linux-security-tools-installer.sh && sudo ./linux-security-tools-installer.sh
```
### Manual Installation
```bash
git clone https://github.com/AhSec0x1/linux-security-tools.git
cd linux-security-tools
sudo chmod +x linux-security-tools-installer.sh
sudo ./linux-security-tools-installer.sh
```
