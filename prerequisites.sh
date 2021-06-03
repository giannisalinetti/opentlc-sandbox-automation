#!/bin/bash

set -eu

PYTHON_PATH=$(which python3)
PACKAGES=(netaddr openshift passlib)
SUDO_PATH=$(which sudo)

if [ -z "${BASH_VERSION:-}" ]; then
  abort "Bash is required to interpret this script."
fi

# print_help prints the script help
function print_help() {
    echo "OpenTLC Sandbox Automation prerequisites script"
    echo "Supported systems: Fedora, macOS"
    echo ""
    echo "Usage: $(basename $0) <fedora|macos>"
}

# print_help_on_err prints a minimal help in case of errors
function print_help_on_err() {
    echo "Usage: $(basename $0) <fedora|macos>"
}

# check_pip installs the pip package manager
function check_pip() {
    echo "=== Check if pip is available ==="
    if [[ -z $($PYTHON_PATH -m pip --version) ]]; then
        curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
        echo "=== Installing pip ==="
        $PYTHON_PATH /tmp/get-pip.py --user
        if [ $? -ne 0 ]; then
            return $?
        fi
    else
        echo "pip already installed"
    fi
    return 0
}

# macos installs ansible on Mac OS using Homebrew
function macos() {
    if [[ "$UNAME_MACHINE" == "arm64" ]]; then
        # On ARM macOS, this script installs to /opt/homebrew only
        HOMEBREW_PREFIX="/opt/homebrew"
    else
        # On Intel macOS, this script installs to /usr/local only
        HOMEBREW_PREFIX="/usr/local"
    fi
    if [[ ! -x $HOMEBREW_PREFIX/brew ]]; then
        echo "Error: Missing homebrew package manager. Install following instructions here: https://brew.sh/index_it"
        return 1
    fi

    echo "=== Installing the Ansible package using Homebrew ==="
    $HOMEBREW_PREFIX/brew install ansible 
    if [[ $? -ne 0 ]]; then
        echo "Error installing Ansible with Homebrew"
        return 1
    fi        
    return 0
}

# fedora installs the ansible package on fedora
function fedora() {
    if [ -x $(which ansible) ]; then
        echo "=== Installing the Ansible package using dnf ==="
        $SUDO_PATH dnf install -y ansible
        if [ $? -ne 0 ]; then
            return 1
        fi
    fi
    return 0
}

# install_python_modules installs required python modules
function install_python_modules() {
    echo "=== Installing required Python modules ==="
    echo "Processed packages:"
    for pkg in ${PACKAGES[@]}; do
        echo $pkg
    done

    for pkg in ${PACKAGES[@]}; do
        $PYTHON_PATH -m pip install --user ${pkg}
        if [[ $? -ne 0 ]]; then
            echo "Error installing package $pkg"
            return 1
        fi        
    done
    return 0
}

# install_collections installs required collections according to the 
# requirements.yml file
function install_collections() {
    echo "=== Installing required Ansible Collections ==="
    if [ ! -f requirements.yml ]; then
        echo "Error: missing requirements.yml file"
        return 1
    fi
    
    ansible-galaxy collection install -r requirements.yml
    if [[ $? -ne 0 ]]; then
        echo "Error: could not install required collections"
        return 1
    fi      
    return 0
}

# test_error is a minimal subroutine to test function returns
function test_error() {
    if [ $1 -ne 0 ]; then
        exit $1
    fi
}

if [ $# -eq 0 ]; then
    echo "Error: missing mandatory system argument"
    print_help_on_err
    exit 1
fi

# Check operating system release and run related functions
case "$1" in
    macos|macOS)
        if [ $(uname -o) == "GNU/Linux" ]; then
            echo "Error: attempted to run macos install argument on a Linux host"
            print_help_on_err
            exit 1
        fi
        macos
        test_error $?
        ;;
    fedora|Fedora)
        if [ -f /etc/fedora-release ] && [ $(cat /etc/fedora-release | awk '{print $1}') == 'Fedora' ]; then
            fedora
            test_error $?
        else
            echo "Error: not a Fedora distribution"
            print_help_on_err
            exit 1
        fi
        ;;
    help|-h|--help)
        print_help
        exit 0
        ;;
    *)
        echo "Error: Unknown argument"
        print_help_on_err
        exit 1
esac

# Run OS independent functions
check_pip
test_error $?

install_python_modules
test_error $?

install_collections
test_error $?

# Print final message
echo "=== Prerequisites installation completed. You can now proceed with the cluster installation. ==="

exit 0
