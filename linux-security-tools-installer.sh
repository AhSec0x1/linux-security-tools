#!/usr/bin/env bash

# =============================================
# Linux Security Tools Installer - Final Version
# Author: AhSec0x1
# Version: 1.0
# License: MIT
# =============================================
# IMPORTANT: This script modifies system configurations
#            and installs security tools. Use with caution!

# Exit immediately if not running on Linux
if [ "$(uname)" != "Linux" ]; then
    echo "This script is designed to run on Linux only."
    exit 1
fi

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script as root or with sudo privileges."
    exit 1
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Initialize variables
INSTALL_SUCCESS=true

# Function to print status messages
print_status() {
    echo -e "${YELLOW}[*]${NC} $1"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

# Function to print error messages
print_error() {
    echo -e "${RED}[✗]${NC} $1"
    INSTALL_SUCCESS=false
}

# Function to detect Linux distribution
detect_distro() {
    print_status "Detecting Linux distribution..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    elif type lsb_release >/dev/null 2>&1; then
        DISTRO=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        DISTRO=$DISTRIB_ID
    elif [ -f /etc/debian_version ]; then
        DISTRO=debian
    elif [ -f /etc/redhat-release ]; then
        DISTRO=centos
    else
        DISTRO=$(uname -s | tr '[:upper:]' '[:lower:]')
    fi
    print_success "Detected distribution: $DISTRO"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install packages based on distribution
install_packages() {
    case $DISTRO in
        ubuntu|debian|kali|linuxmint)
            print_status "Ubuntu/Debian based system detected"
            
            # Update package lists and upgrade system
            print_status "Updating package lists and upgrading system..."
            sudo apt-get update && sudo apt-get upgrade -y
            
            # Install basic dependencies with libpcap-dev FIRST
            print_status "Installing dependencies..."
            sudo apt-get install -y libpcap-dev build-essential python3 python3-pip git wget curl nmap docker.io golang
            
            # Configure Docker
            print_status "Configuring Docker..."
            sudo systemctl enable docker
            sudo systemctl start docker
            sudo usermod -aG docker "$SUDO_USER"
            ;;
            
        centos|rhel|fedora|rocky|almalinux)
            print_status "CentOS/RHEL/Fedora based system detected"
            
            # Update system
            print_status "Updating system..."
            if command_exists dnf; then
                sudo dnf update -y
            else
                sudo yum update -y
            fi
            
            # Install basic dependencies with libpcap-devel
            print_status "Installing dependencies..."
            if command_exists dnf; then
                sudo dnf install -y libpcap-devel gcc python3 python3-pip git wget curl nmap docker golang
            else
                sudo yum install -y libpcap-devel gcc python3 python3-pip git wget curl nmap docker golang
            fi
            
            # Configure Docker
            print_status "Configuring Docker..."
            sudo systemctl enable docker
            sudo systemctl start docker
            sudo usermod -aG docker "$SUDO_USER"
            ;;
            
        arch|manjaro|endeavouros)
            print_status "Arch/Manjaro based system detected"
            
            # Update system
            print_status "Updating system..."
            sudo pacman -Syu --noconfirm
            
            # Install basic dependencies with libpcap
            print_status "Installing dependencies..."
            sudo pacman -S --noconfirm libpcap base-devel python python-pip git wget curl nmap docker go
            
            # Configure Docker
            print_status "Configuring Docker..."
            sudo systemctl enable docker
            sudo systemctl start docker
            sudo usermod -aG docker "$SUDO_USER"
            ;;
            
        *)
            print_error "Unsupported Linux distribution: $DISTRO"
            exit 1
            ;;
    esac
}

# Function to install Go tools with comprehensive error handling
install_go_tools() {
    local INSTALL_USER=$(logname)
    export GOPATH="/home/$INSTALL_USER/go"
    export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
    
    # Ensure directories exist with correct permissions
    sudo -u "$INSTALL_USER" mkdir -p "$GOPATH/bin"
    
    # Update bashrc for the actual user
    echo "export GOPATH=$GOPATH" | sudo -u "$INSTALL_USER" tee -a "/home/$INSTALL_USER/.bashrc"
    echo "export PATH=\$PATH:/usr/local/go/bin:$GOPATH/bin" | sudo -u "$INSTALL_USER" tee -a "/home/$INSTALL_USER/.bashrc"

    # List of tools to install
    declare -A tools=(
        ["subfinder"]="github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
        ["httpx"]="github.com/projectdiscovery/httpx/cmd/httpx@latest"
        ["nuclei"]="github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest"
        ["naabu"]="github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
    )
    
    # Install each tool with comprehensive error handling
    for tool in "${!tools[@]}"; do
        print_status "Installing $tool..."
        
        # Special handling for naabu
        if [ "$tool" == "naabu" ]; then
            # Verify pcap development files are installed
            if ! ldconfig -p | grep -q libpcap; then
                print_error "libpcap not found - attempting to reinstall"
                case $DISTRO in
                    ubuntu|debian|kali|linuxmint)
                        sudo apt-get install -y --reinstall libpcap-dev
                        ;;
                    centos|rhel|fedora|rocky|almalinux)
                        sudo yum reinstall -y libpcap-devel
                        ;;
                    arch|manjaro|endeavouros)
                        sudo pacman -S --noconfirm libpcap
                        ;;
                esac
            fi
        fi
        
        # Installation attempt with debug output
        if ! sudo -u "$INSTALL_USER" env PATH=$PATH GOPATH=$GOPATH go install -v "${tools[$tool]}" 2>&1 | tee /tmp/go_install.log; then
            print_error "Initial $tool installation failed"
            print_status "Checking build logs..."
            cat /tmp/go_install.log
            
            # Attempt to fix common issues
            case $tool in
                naabu)
                    print_status "Attempting to fix naabu dependencies..."
                    sudo -u "$INSTALL_USER" env PATH=$PATH GOPATH=$GOPATH go clean -modcache
                    sudo -u "$INSTALL_USER" env PATH=$PATH GOPATH=$GOPATH go get -u github.com/gopacket/gopacket
                    ;;
            esac
            
            # Retry installation
            print_status "Retrying $tool installation..."
            if ! sudo -u "$INSTALL_USER" env PATH=$PATH GOPATH=$GOPATH go install -v "${tools[$tool]}"; then
                print_error "Failed to install $tool after retry"
                continue
            fi
        fi

        # Verify installation
        if [ -f "$GOPATH/bin/$tool" ]; then
            sudo ln -sf "$GOPATH/bin/$tool" "/usr/local/bin/$tool"
            print_success "$tool installed successfully"
        else
            print_error "$tool binary not found after installation"
        fi
    done
}

# Function to verify installations
verify_installations() {
    echo -e "\nVerification Results:"
    
    # Core tools verification
    verify_tool "python3" "--version" "Python"
    verify_tool "go" "version" "go"
    verify_tool "docker" "--version" "Docker"
    verify_tool "nmap" "--version" "Nmap"
    
    # Security tools verification
    verify_tool "subfinder" "-version" "subfinder"
    verify_tool "httpx" "-version" "httpx"
    verify_tool "nuclei" "-version" "nuclei"
    verify_tool "naabu" "-version" "naabu"
}

# Function to verify individual tool
verify_tool() {
    local tool=$1
    local arg=$2
    local name=${3:-$tool}
    
    if command_exists "$tool"; then
        if output=$($tool $arg 2>&1); then
            print_success "$name working"
            return 0
        fi
    fi
    
    # Check in GOPATH if not found system-wide
    if [ -f "$GOPATH/bin/$tool" ]; then
        if output=$("$GOPATH/bin/$tool" $arg 2>&1); then
            print_success "$name working (in GOPATH)"
            return 0
        fi
    fi
    
    print_error "$name not working"
    return 1
}

# Main script execution
echo -e "\nStarting Linux security tools installation..."
detect_distro
install_packages
install_go_tools
verify_installations

# Completion message
if $INSTALL_SUCCESS; then
    print_success "\nAll tools installed successfully!"
else
    print_error "\nSome tools failed to install completely"
fi

echo -e "\nImportant notes:"
echo "1. You may need to log out and back in for:"
echo "   - Docker group permissions"
echo "   - PATH updates to take effect"
echo "2. Go tools are installed in: $GOPATH/bin"
echo "3. Run 'source ~/.bashrc' or restart your terminal"
echo -e "\nTo update tools: go install -v [tool-package]@latest"
