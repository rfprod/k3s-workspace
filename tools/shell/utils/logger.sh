#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
