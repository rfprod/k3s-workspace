#!/bin/bash

##############################################################################
# K3s Install/Uninstall Utility.
# A utility script for local k3s experiments and training.
# Usage: ./k3s-utility.sh [install|uninstall]
##############################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
K3S_VERSION="${K3S_VERSION:-latest}"
KUBECONFIG="${HOME}/.kube/config"

# Log an info message.
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

# Log a success message.
log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

# Log a warning message.
log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

# Log an error message.
log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Root permission checker.
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run with sudo"
        exit 1
    fi
}

# OS release checker.
check_os() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot detect OS"
        exit 1
    fi
    source /etc/os-release
    log_info "Detected OS: $PRETTY_NAME"
}

# Missing dependency checker.
check_dependencies() {
    local MISSING_DEPS=()

    for CMD_NAME in curl wget systemctl; do
        if ! command -v "$CMD_NAME" &> /dev/null; then
            MISSING_DEPS+=("$CMD_NAME")
        fi
    done

    if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${MISSING_DEPS[*]}"
        log_info "Please install missing packages and try again"
        exit 1
    fi
}

##
# Installs k3s.
##
install_k3s() {
    log_info "Starting k3s installation..."
    check_root
    check_os
    check_dependencies

    # Check if k3s is already installed
    if command -v k3s &> /dev/null; then
        log_warn "k3s is already installed"
        local CURRENT_VERSION
        CURRENT_VERSION=$(k3s --version | head -n1)
        log_info "Current version: $CURRENT_VERSION"
        read -p "Do you want to continue? This may upgrade k3s. (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled"
            return 0
        fi
    fi

    log_info "Installing k3s (version: $K3S_VERSION)..."

    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3S_VERSION" sh -

    # shellcheck disable=SC2181
    if [[ $? -ne 0 ]]; then
        log_error "k3s installation failed"
        exit 1
    fi

    log_info "Waiting for k3s to be ready..."
    local MAX_ATTEMPTS
    MAX_ATTEMPTS=30
    local ATTEMPT
    ATTEMPT=0

    while [[ $ATTEMPT -lt $MAX_ATTEMPTS ]]; do
        if systemctl is-active --quiet k3s; then
            log_success "k3s service is running"
            break
        fi
        ATTEMPT=$((ATTEMPT + 1))
        sleep 1
    done

    if [[ $ATTEMPT -eq $MAX_ATTEMPTS ]]; then
        log_error "k3s service failed to start within timeout"
        exit 1
    fi

    log_info "Setting up kubeconfig..."
    mkdir -p "$(dirname "$KUBECONFIG")"
    sudo cat /etc/rancher/k3s/k3s.yaml | sed "s|127.0.0.1|$(hostname -I | awk '{print $1}')|g" > "$KUBECONFIG"
    chmod 600 "$KUBECONFIG"

    log_info "Verifying installation..."
    kubectl cluster-info
    kubectl get nodes

    log_success "k3s installation completed successfully!"
    log_info "kubeconfig location: $KUBECONFIG"
    log_info "To use kubectl, run: export KUBECONFIG=$KUBECONFIG"
}

##
# Uninstalls k3s.
##
uninstall_k3s() {
    log_info "Starting k3s uninstallation..."
    check_root

    if ! command -v k3s &> /dev/null; then
        log_warn "k3s does not appear to be installed"
        return 0
    fi

    read -p "Are you sure you want to uninstall k3s? This will stop and remove all k3s components. (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Uninstallation cancelled"
        return 0
    fi

    if systemctl is-active --quiet k3s; then
        log_info "Stopping k3s service..."
        systemctl stop k3s
    fi

    log_info "Running k3s uninstall script..."
    local UNINSTALL_SCRIPT_PATH
    UNINSTALL_SCRIPT_PATH=/usr/local/bin/k3s-uninstall.sh
    if [[ -f "$UNINSTALL_SCRIPT_PATH" ]]; then
        bash "$UNINSTALL_SCRIPT_PATH"
    else
        log_error "k3s uninstall script not found"
        exit 1
    fi

    log_info "Cleaning up kubeconfig..."
    if [[ -f "$KUBECONFIG" ]]; then
        rm -f "$KUBECONFIG"
        log_info "Removed kubeconfig: $KUBECONFIG"
    fi

    log_info "Cleaning up k3s directories..."
    rm -rf /etc/rancher/k3s 2>/dev/null || true
    rm -rf /var/lib/rancher/k3s 2>/dev/null || true

    log_success "k3s uninstallation completed successfully!"
}

##
# Prints k3s status.
##
status_k3s() {
    if command -v k3s &> /dev/null; then
        log_success "k3s is installed"
        k3s --version | head -n1

        if systemctl is-active --quiet k3s; then
            log_success "k3s service is running"
            kubectl cluster-info 2>/dev/null || log_warn "Cannot connect to cluster"
        else
            log_warn "k3s service is not running"
        fi
    else
        log_warn "k3s is not installed"
    fi
}

##
# Prints script usage instructions.
##
usage() {
    cat << EOF
Usage: $(basename "$0") [COMMAND]

Commands:
    install     Install k3s
    uninstall   Uninstall k3s
    status      Check k3s installation status
    help        Show this help message

Environment Variables:
    K3S_VERSION    Specify k3s version (default: latest)
                   Example: K3S_VERSION=v1.27.0 ./$(basename "$0") install

Examples:
    sudo ./$(basename "$0") install
    sudo ./$(basename "$0") uninstall
    ./$(basename "$0") status
    sudo K3S_VERSION=v1.27.0 ./$(basename "$0") install

EOF
}

##
# The entrypoint.
##
main() {
    local COMMAND
    COMMAND="${1:-help}"

    case "$COMMAND" in
        install)
            install_k3s
            ;;
        uninstall)
            uninstall_k3s
            ;;
        status)
            status_k3s
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            usage
            exit 1
            ;;
    esac
}

main "$@"
