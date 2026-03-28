#!/usr/bin/env bash
# packages/manager.sh - Main orchestration for dotfile linking/unlinking
# 
# API Contract:
# - Uses global state from cli/args.sh (PACKAGES_TO_PROCESS, LINK_SRC_BASE_DIR, QUIET)
# - Depends on lib/logging.sh (print_header, print_message, color vars)
# - Depends on lib/utils.sh (resolve_path)
# - Depends on packages/operations.sh (process_single_item, reconcile_*_runtime)
#
# This module provides the main orchestration function for managing dotfiles,
# handling all package types including special cases for factory, cliproxy, omp,
# and macOS-specific packages like aerospace, sketchybar, borders, and ghostty.

# Ensure strict mode for this module
set -euo pipefail

# manage_dotfiles: Main orchestration function for linking/unlinking dotfiles
# Args: $1 - action ("link" or "unlink")
# Uses global variables: PACKAGES_TO_PROCESS, LINK_SRC_BASE_DIR, QUIET
manage_dotfiles() {
  local action="$1"
  local header_msg=""
  if [ "$action" = "link" ]; then header_msg="Linking Dotfiles (Manual Symlinks)"; else header_msg="Unlinking Dotfiles (Manual Symlinks)"; fi
  print_header "$header_msg"

  # Enable more verbose debugging
  set -E  # Inherit error trap
  trap 'echo -e "\033[0;31mERROR: Command failed at line $LINENO: $BASH_COMMAND\033[0m"' ERR

  local packages_to_act_on_arr=()
  if [ -n "$PACKAGES_TO_PROCESS" ]; then
    IFS=',' read -ra packages_to_act_on_arr <<< "$PACKAGES_TO_PROCESS"
  else
    mapfile -t packages_to_act_on_arr < <(get_available_packages)
  fi

  if [ ${#packages_to_act_on_arr[@]} -eq 0 ]; then
    print_message "$YELLOW" "No packages specified or found to $action."
    return 0
  fi

  if [ "$QUIET" = false ]; then print_message "$BLUE" "Packages to $action: ${packages_to_act_on_arr[*]}"; fi
  local overall_succ_cnt=0 overall_fail_cnt=0 overall_fail_list=()
  local ts; ts=$(date +%Y%m%d_%H%M%S)
  local main_backup_dir="$HOME/.dotfiles_backup/$ts"
  backup_made_globally=false

  echo -e "${PURPLE}DEBUG: Starting package processing loop with ${#packages_to_act_on_arr[@]} packages${NC}"

  for package_name in "${packages_to_act_on_arr[@]}"; do
    echo -e "${PURPLE}DEBUG: Starting to process package '$package_name'${NC}"
    local package_source_dir="$LINK_SRC_BASE_DIR/$package_name"
    if [ ! -d "$package_source_dir" ]; then
      print_message "$YELLOW" "Package source directory '$package_source_dir' not found. Skipping '$package_name'."
      overall_fail_cnt=$((overall_fail_cnt + 1)); overall_fail_list+=("$package_name (src dir missing)")
      continue
    fi
    if [ "$QUIET" = false ]; then print_message "$CYAN" "Processing package '$package_name':"; fi
    echo -e "${PURPLE}DEBUG: Processing package '$package_name' from '$package_source_dir'${NC}"

    local items_processed_in_package=0
    local items_succeeded_in_package=0
    local items_failed_in_package=0

    # Rule 1: Top-level non-dot-prefixed directories (like nvim, starship) link to ~/.config/
    if [[ "$package_name" != .* ]]; then # e.g. "nvim", "starship"
      # Skip macOS-only packages on non-macOS systems
      if [[ ("$package_name" == "aerospace" || "$package_name" == "sketchybar" || "$package_name" == "borders") && "$(uname -s)" != "Darwin" ]]; then
        if [ "$QUIET" = false ]; then print_message "$YELLOW" "  Skipping '$package_name': macOS-only package (current OS: $(uname -s))"; fi
      elif [[ "$package_name" == "factory" ]]; then
        local factory_target_dir="$HOME/.factory"
        if [ -d "$package_source_dir" ]; then
          items_processed_in_package=$((items_processed_in_package + 1))
          echo -e "${PURPLE}  DEBUG: Applying Factory directory linking${NC}"
          if process_single_item "$action" "$package_source_dir" "$factory_target_dir" "factory" "$main_backup_dir"; then
            items_succeeded_in_package=$((items_succeeded_in_package + 1))
          else
            items_failed_in_package=$((items_failed_in_package + 1))
          fi
        else
          if [ "$QUIET" = false ]; then print_message "$YELLOW" "  Skipping 'factory': package directory not found."; fi
        fi
      elif [[ "$package_name" == "cliproxy" ]]; then
        items_processed_in_package=$((items_processed_in_package + 1))
        echo -e "${PURPLE}  DEBUG: Applying CLIProxy directory linking${NC}"
        if process_single_item "$action" "$package_source_dir" "$HOME/.cliproxy" "cliproxy" "$main_backup_dir"; then
          if [ "$action" = "link" ]; then
            reconcile_cliproxy_runtime "$package_source_dir" "$main_backup_dir/cliproxy"
          fi
          items_succeeded_in_package=$((items_succeeded_in_package + 1))
        else
          items_failed_in_package=$((items_failed_in_package + 1))
        fi
      elif [[ "$package_name" == "omp" ]]; then
        items_processed_in_package=$((items_processed_in_package + 1))
        echo -e "${PURPLE}  DEBUG: Applying OMP directory linking${NC}"
        if process_single_item "$action" "$package_source_dir" "$HOME/.omp" "omp" "$main_backup_dir"; then
          if [ "$action" = "link" ]; then
            reconcile_omp_runtime "$package_source_dir" "$main_backup_dir/omp"
          fi
          items_succeeded_in_package=$((items_succeeded_in_package + 1))
        else
          items_failed_in_package=$((items_failed_in_package + 1))
        fi
      else
        echo -e "${PURPLE}  DEBUG: Applying Rule 1 for '$package_name'${NC}"
        items_processed_in_package=$((items_processed_in_package + 1))
        if process_single_item "$action" "$package_source_dir" "$HOME/.config/$package_name" "$package_name" "$main_backup_dir"; then
          items_succeeded_in_package=$((items_succeeded_in_package + 1))
        else
          items_failed_in_package=$((items_failed_in_package + 1))
        fi
      fi

      # Special handling for ghostty on macOS - link config file directly
      if [[ "$package_name" == "ghostty" && "$(uname -s)" == "Darwin" ]]; then
        local ghostty_config_source="$package_source_dir/config"
        local ghostty_config_target="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
        if [ -f "$ghostty_config_source" ]; then
          items_processed_in_package=$((items_processed_in_package + 1))
          echo -e "${PURPLE}  DEBUG: Applying Ghostty macOS-specific config linking${NC}"
          if process_single_item "$action" "$ghostty_config_source" "$ghostty_config_target" "ghostty/macOS-config" "$main_backup_dir"; then
            items_succeeded_in_package=$((items_succeeded_in_package + 1))
          else
            items_failed_in_package=$((items_failed_in_package + 1))
          fi
        fi
      fi
    fi

    # Rule 2: For specific packages, look *inside* them for specific dotfiles to link to home
    echo -e "${PURPLE}  DEBUG: Applying Rule 2 for '$package_name'${NC}"
    local found_items_in_package=()

    # Use a safer approach to find dot files
    echo -e "${PURPLE}  DEBUG: Searching for dot items in '$package_source_dir'${NC}"
    while IFS= read -r -d '' item; do
      local item_basename=$(basename "$item")
      echo -e "${PURPLE}    DEBUG: Found item: $item_basename${NC}"

      # Only link specific dotfiles (.zshrc, .tmux, .tmux.conf, .claude) to home directory
      if [[ "$item_basename" == ".zshrc" || "$item_basename" == ".tmux" || "$item_basename" == ".tmux.conf" || "$item_basename" == ".claude" ]]; then
        found_items_in_package+=("$item")
        echo -e "${PURPLE}    DEBUG: Added to processing list: $item${NC}"
      else
        echo -e "${PURPLE}    DEBUG: Skipping item (not in allowed home dotfiles): $item_basename${NC}"
      fi
    done < <(find "$package_source_dir" -mindepth 1 -maxdepth 1 -name ".*" -print0 2>/dev/null || echo -e "${RED}Find command failed!${NC}")

    echo -e "${PURPLE}  DEBUG: Found ${#found_items_in_package[@]} dot-items in '$package_name'${NC}"

    if [ ${#found_items_in_package[@]} -gt 0 ]; then
      echo -e "${PURPLE}    DEBUG: Found dot-items in '$package_name': ${found_items_in_package[*]}${NC}"
      for source_item_abs_path in "${found_items_in_package[@]}"; do
        local item_basename; item_basename=$(basename "$source_item_abs_path")
        echo -e "${PURPLE}      DEBUG: Processing inner item '$item_basename' from '$package_name'${NC}"
        items_processed_in_package=$((items_processed_in_package + 1))
        if process_single_item "$action" "$source_item_abs_path" "$HOME/$item_basename" "$item_basename" "$main_backup_dir"; then
          items_succeeded_in_package=$((items_succeeded_in_package + 1))
        else
          items_failed_in_package=$((items_failed_in_package + 1))
        fi
      done
    fi

    if [ "$QUIET" = false ] && [ $items_processed_in_package -gt 0 ]; then
      if [ $items_failed_in_package -eq 0 ]; then
        print_message "$GREEN" "  Package '$package_name' processed successfully ($items_succeeded_in_package item(s))."
      else
        print_message "$YELLOW" "  Package '$package_name': $items_succeeded_in_package/$items_processed_in_package item(s) succeeded."
      fi
    fi

    if [ $items_processed_in_package -gt 0 ]; then # Only count package if items were attempted
      if [ $items_failed_in_package -eq 0 ]; then
        overall_succ_cnt=$((overall_succ_cnt + 1))
      else
        overall_fail_cnt=$((overall_fail_cnt + 1))
        overall_fail_list+=("$package_name (partial/full failure)")
      fi
    fi

    echo -e "${PURPLE}DEBUG: Completed processing package '$package_name'${NC}"
  done

  # Disable the error trap
  trap - ERR
  set +E

  echo; print_message "$BLUE" "$action Summary"
  print_message "$GREEN" "Packages fully successful: $overall_succ_cnt" # Changed wording
  if [ $overall_fail_cnt -gt 0 ]; then
    print_message "$RED" "Packages with failures or not processed as expected: $overall_fail_cnt (${overall_fail_list[*]}). Check output."
  fi
  if [ "$action" = "link" ] && [ "$backup_made_globally" = true ]; then
    if [ -d "$main_backup_dir" ] && [ "$(ls -A "$main_backup_dir")" ]; then
      echo; print_message "$BLUE" "Backups created in $main_backup_dir"
    fi
  fi

  if [ $overall_fail_cnt -eq 0 ]; then
    # Success if no failures, even if succ_cnt is 0 (e.g. unlinking already unlinked items)
    print_message "$GREEN" "✨ All specified packages processed successfully for $action!"
    return 0
  else
    print_message "$RED" "⚠️ Some packages had issues during $action. Review logs."
    return 1
  fi
}
