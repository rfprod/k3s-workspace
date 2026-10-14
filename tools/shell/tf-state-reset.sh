#!/bin/bash

##############################################################################
# Terraform State Reset Utility.
# A utility script for resetting local Terraform state.
# Usage: ./tf-state-reset.sh
##############################################################################

source ./tools/shell/utils/config.sh

source ./tools/shell/utils/logger.sh

main() {
  local SCRIPT_DIR
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

  local PROJECT_ROOT
  PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd -P)"

  local CURRENT_DIR
  CURRENT_DIR="$(pwd -P)"

  local TERRAFORM_DIR
  TERRAFORM_DIR="$PROJECT_ROOT/terraform"

  if [[ "$CURRENT_DIR" != "$PROJECT_ROOT" ]]; then
    log_error "Error: Run this script from the project root."
    log_info "Note: The project root is the directory containing tools/shell/tf-state-reset.sh and terraform/."
    exit 1
  fi

  if [[ ! -d "$TERRAFORM_DIR" ]]; then
    log_error "Error: $TERRAFORM_DIR is not found."
    exit 1
  fi

  cd "$TERRAFORM_DIR"

  local TFVARS_PATH
  TFVARS_PATH="./deploy.tfvars"

  if [[ ! -f "$TFVARS_PATH" ]]; then
    log_info "$TFVARS_PATH is not found. Skipping 'terraform destroy'."
  else
    # Runs Terraform's normal confirmation prompt. If destroy fails or is cancelled,
    # set -e stops the script before any files are removed.
    terraform destroy -var-file="$TFVARS_PATH"
  fi

  shopt -s nullglob
  local STATE_FILES
  STATE_FILES=(./.terraform* ./terraform.tfstate* ./tfplan ./*.tfplan)

  rm -rf -- "${STATE_FILES[@]}"

  log_success "Terraform destroy completed; local state and plan files removed."
}

main
