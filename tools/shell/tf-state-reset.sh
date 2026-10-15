#!/bin/bash

###################################################################################
# Terraform State Reset Utility.
# A utility script for resetting local Terraform state across multiple directories.
# Usage: ./tf-state-reset.sh [selection]
# Examples:
#   ./tf-state-reset.sh              (interactive menu)
#   ./tf-state-reset.sh 1            (select first directory)
#   ./tf-state-reset.sh 1,3,4        (select directories 1, 3, and 4)
#   ./tf-state-reset.sh all          (select all directories)
###################################################################################

source ./tools/shell/utils/config.sh
source ./tools/shell/utils/logger.sh

main() {
  local SCRIPT_DIR
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

  local PROJECT_ROOT
  PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd -P)"

  local CURRENT_DIR
  CURRENT_DIR="$(pwd -P)"

  # Define all Terraform directories to support
  local -a TERRAFORM_DIRS=(
    "$PROJECT_ROOT/terraform"
    "$PROJECT_ROOT/terraform_mod/environments/dev"
    "$PROJECT_ROOT/terraform_mod/environments/staging"
    "$PROJECT_ROOT/terraform_mod/environments/production"
  )

  if [[ "$CURRENT_DIR" != "$PROJECT_ROOT" ]]; then
    log_error "Error: Run this script from the project root."
    log_info "Note: The project root is the directory containing tools/shell/tf-state-reset.sh."
    exit 1
  fi

  # Validate that at least one Terraform directory exists
  validate_terraform_dirs "${TERRAFORM_DIRS[@]}"

  # Get valid directories (those that exist)
  # shellcheck disable=SC2034
  local -a VALID_DIRS_ARR=()
  get_valid_dirs VALID_DIRS_ARR "${TERRAFORM_DIRS[@]}"

  # Display menu and get user selection
  local -a selected_dirs
  if [[ -z "$1" ]]; then
    # Interactive mode: no parameter provided
    select_terraform_dirs_interactive selected_dirs VALID_DIRS_ARR
  else
    # Parameter mode: use provided selection
    select_terraform_dirs_from_param selected_dirs VALID_DIRS_ARR "$1"
  fi

  selected_dirs=("${selected_dirs[@]}")

  if [[ ${#selected_dirs[@]} -eq 0 ]]; then
    log_info "No directories selected. Exiting."
    exit 0
  fi

  log_info "Resetting Terraform state for ${#selected_dirs[@]} directory(ies)..."
  echo ""

  # Process each selected directory
  local failed_dirs=()
  for terraform_dir in "${selected_dirs[@]}"; do
    reset_terraform_state "$terraform_dir" || failed_dirs+=("$terraform_dir")
  done

  echo ""
  if [[ ${#failed_dirs[@]} -eq 0 ]]; then
    log_success "All Terraform state resets completed successfully."
    exit 0
  else
    log_error "Failed to reset state in the following directories:"
    printf '%s\n' "${failed_dirs[@]}" | sed 's/^/  - /'
    exit 1
  fi
}

validate_terraform_dirs() {
  local FOUND_ANY
  FOUND_ANY=0

  for DIR_NAME in "$@"; do
    if [[ -d "$DIR_NAME" ]]; then
      FOUND_ANY=1
      break
    fi
  done

  if [[ $FOUND_ANY -eq 0 ]]; then
    log_error "Error: No Terraform directories found."
    log_info "Checked:"
    printf '%s\n' "$@" | sed 's/^/  - /'
    exit 1
  fi
}

get_valid_dirs() {
  local -n RESULT=$1
  shift
  RESULT=()

  for DIR_NAME in "$@"; do
    if [[ -d "$DIR_NAME" ]]; then
      RESULT+=("$DIR_NAME")
    fi
  done
}

select_terraform_dirs_interactive() {
  local selected_var=$1
  local valid_dirs_var=$2

  log_info "Available Terraform directories:"
  echo ""

  local -n valid_dirs=$valid_dirs_var
  local index=1
  for dir in "${valid_dirs[@]}"; do
    local display_name="${dir#"$PROJECT_ROOT"/}"
    printf "  %d) %s\n" "$index" "$display_name"
    ((index++))
  done

  echo ""
  log_info "Select directories to reset (comma-separated numbers, or 'all'):"
  log_info "Example: 1,2,4 or all"
  echo ""

  local USER_INPUT
  read -r USER_INPUT

  # Call parse_selections with variable names (as strings)
  parse_selections "$selected_var" "$valid_dirs_var" "$USER_INPUT"
}

select_terraform_dirs_from_param() {
  local selected_var=$1
  local valid_dirs_var=$2
  local param="$3"

  parse_selections "$selected_var" "$valid_dirs_var" "$param"
}

parse_selections() {
  local selected_var=$1
  local valid_dirs_var=$2
  local user_input="$3"

  # Create namerefs at the lowest level
  local -n selected=$selected_var
  local -n valid_dirs=$valid_dirs_var
  selected=()

  if [[ "$user_input" == "all" ]]; then
    selected=("${valid_dirs[@]}")
  else
    IFS=',' read -ra selections <<< "$user_input"
    for selection in "${selections[@]}"; do
      selection=$(echo "$selection" | xargs)
      if [[ "$selection" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#valid_dirs[@]} )); then
        selected+=("${valid_dirs[$((selection - 1))]}")
      else
        log_error "Invalid selection: $selection (valid range: 1-${#valid_dirs[@]})"
        exit 1
      fi
    done
  fi

  # selected=($(printf '%s\n' "${selected[@]}" | sort -u))
  mapfile -t selected < <(printf '%s\n' "${selected[@]}" | sort -u)
}


reset_terraform_state() {
  local terraform_dir="$1"
  local display_name="${terraform_dir#"$PROJECT_ROOT"/}"

  log_info "Processing: $display_name"

  # Change to the Terraform directory
  if ! cd "$terraform_dir" 2>/dev/null; then
    log_error "  Failed to enter directory: $terraform_dir"
    return 1
  fi

  local TFVARS_PATH
  TFVARS_PATH="./deploy.tfvars"

  if [[ ! -f "$TFVARS_PATH" ]]; then
    log_info "  $TFVARS_PATH not found. Skipping 'terraform destroy'."
  else
    log_info "  Running 'terraform destroy'..."
    if ! terraform destroy -var-file="$TFVARS_PATH"; then
      log_error "  Terraform destroy failed or was cancelled."
      cd "$PROJECT_ROOT"
      return 1
    fi
  fi

  # Clean up state files and plans
  shopt -s nullglob
  local STATE_FILES
  STATE_FILES=(./.terraform* ./terraform.tfstate* ./tfplan ./*.tfplan)

  if [[ ${#STATE_FILES[@]} -gt 0 ]]; then
    rm -rf -- "${STATE_FILES[@]}"
    log_info "  Local state and plan files removed."
  fi

  log_success "  Reset completed for $display_name"

  # Return to project root for next iteration
  cd "$PROJECT_ROOT"
  return 0
}

main "$@"
