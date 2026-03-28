#!/usr/bin/env bash
#
# packages/operations.sh - Dotfile link/unlink operations
#
# This module provides functions for linking and unlinking dotfiles.
#
# Dependencies:
#   - lib/logging.sh (print_message, color variables: PURPLE, RED, GREEN, YELLOW, BLUE, CYAN, GRAY, NC)
#   - lib/utils.sh (resolve_path)
#
# Global variables used:
#   - QUIET (boolean): Minimize output when true
#   - backup_made_globally (boolean): Set to true when backups are made
#   - main_backup_dir (string): Directory for storing backups

# process_single_item()
# Process a single dotfile item (link or unlink)
# Arguments:
#   $1 - action: "link" or "unlink"
#   $2 - source_path: Path to the source file/directory
#   $3 - target_path: Path where the symlink should be created
#   $4 - display_name: Human-readable name for the item
#   $5 - main_backup_dir: Directory for storing backups
# Returns: 0 on success, 1 on failure
process_single_item() {
  local action="$1"
  local source_path="$2"
  local target_path="$3"
  local display_name="$4"
  local main_backup_dir="$5"

  echo -e "${PURPLE}  DEBUG: process_single_item: action='$action', source='$source_path', target='$target_path', name='$display_name'${NC}"

  if [ "$action" = "link" ]; then
    if [ ! -e "$source_path" ]; then
        print_message "$RED" "  ERROR: Source path '$source_path' for '$display_name' does not exist. Skipping."
        return 1
    fi
    local target_parent_dir; target_parent_dir=$(dirname "$target_path")
    if [ ! -d "$target_parent_dir" ]; then
      if [ "$QUIET" = false ]; then print_message "$BLUE" "  Creating parent directory '$target_parent_dir' for '$display_name'"; fi
      if ! mkdir -p "$target_parent_dir"; then
        print_message "$RED" "  ERROR: Failed to create parent directory '$target_parent_dir' for '$display_name'."; return 1
      fi
    fi

    if [ -L "$target_path" ]; then
      local current_link_target; current_link_target=$(resolve_path "$target_path" 2>/dev/null || true)
      local expected_link_target; expected_link_target=$(resolve_path "$source_path" 2>/dev/null || true)
      echo -e "${PURPLE}    DEBUG: Target '$target_path' is a symlink. Current: '$current_link_target', Expected: '$expected_link_target'${NC}"
      if [[ "$current_link_target" == "$expected_link_target" ]]; then
        if [ "$QUIET" = false ]; then print_message "$GREEN" "  Symlink '$target_path' for '$display_name' already correct."; fi
        return 0 
      else
        if ask_yes_no "  Target '$target_path' for '$display_name' is a symlink pointing to '$current_link_target'. Replace it?" "y"; then
          if [ "$QUIET" = false ]; then print_message "$BLUE" "    Removing existing symlink '$target_path'"; fi
          if ! rm "$target_path"; then
             print_message "$RED" "    ERROR: Failed to remove existing symlink '$target_path'."; return 1
          fi
        else
          if [ "$QUIET" = false ]; then print_message "$YELLOW" "    Skipping replacement of symlink '$target_path'."; fi
          return 1 
        fi
      fi
    elif [ -e "$target_path" ]; then
      local conflict_desc="item"; if [ -d "$target_path" ]; then conflict_desc="directory"; elif [ -f "$target_path" ]; then conflict_desc="file"; fi
      echo -e "${PURPLE}    DEBUG: Target '$target_path' exists and is a $conflict_desc.${NC}"
      if ask_yes_no "  Target '$target_path' for '$display_name' ($conflict_desc) exists. Backup & remove it?" "y"; then
        backup_made_globally=true 
        local item_backup_path="$main_backup_dir/$display_name" 
        if [ "$QUIET" = false ]; then print_message "$BLUE" "    Backing up '$target_path' to '$item_backup_path'"; fi
        mkdir -p "$(dirname "$item_backup_path")"
        if cp -RL "$target_path" "$item_backup_path"; then
          if [ "$QUIET" = false ]; then print_message "$GRAY" "      Backed up."; fi
          if [ "$QUIET" = false ]; then print_message "$BLUE" "    Removing '$target_path'"; fi
          if ! rm -rf "$target_path"; then
            print_message "$RED" "    ERROR: Failed to remove '$target_path'."; return 1
          fi
        else
          print_message "$RED" "    ERROR: Failed to backup '$target_path'."; return 1
        fi
      else
        if [ "$QUIET" = false ]; then print_message "$YELLOW" "    Skipping removal of '$target_path'."; fi
        return 1 
      fi
    fi
    if [ "$QUIET" = false ]; then echo -n -e "${CYAN}  Linking '$source_path' to '$target_path'... ${NC}"; fi
    if ln -sfn "$source_path" "$target_path"; then
      if [ "$QUIET" = false ]; then echo -e "${GREEN}✓ Linked${NC}"; fi
      return 0
    else
      if [ "$QUIET" = false ]; then echo -e "${RED}✗ Link Failed${NC}"; fi
      print_message "$RED" "  ERROR: Failed to link '$display_name'."
      return 1
    fi

  elif [ "$action" = "unlink" ]; then
    if [ ! -L "$target_path" ]; then
      if [ -e "$target_path" ] && [ "$QUIET" = false ]; then
        print_message "$YELLOW" "  Skipping '$target_path' for '$display_name': Not a symlink."
      elif [ "$QUIET" = false ] && [ ! -e "$target_path" ]; then
         echo -e "${PURPLE}    DEBUG: Target '$target_path' for unlink does not exist.${NC}"
      fi
      return 0 
    fi

    local current_link_target; current_link_target=$(resolve_path "$target_path" 2>/dev/null || true)
    local expected_link_target; expected_link_target=$(resolve_path "$source_path" 2>/dev/null || true)
    echo -e "${PURPLE}    DEBUG: Target '$target_path' is a symlink. Current: '$current_link_target', Expected: '$expected_link_target'${NC}"

    if [[ "$current_link_target" == "$expected_link_target" ]]; then
      if [ "$QUIET" = false ]; then echo -n -e "${CYAN}  Unlinking '$target_path' for '$display_name'... ${NC}"; fi
      if rm "$target_path"; then
        if [ "$QUIET" = false ]; then echo -e "${GREEN}✓ Unlinked${NC}"; fi
        return 0
      else
        if [ "$QUIET" = false ]; then echo -e "${RED}✗ Failed to remove${NC}"; fi
        print_message "$RED" "  ERROR: Failed to remove symlink '$target_path'."
        return 1
      fi
    else
      if [ "$QUIET" = false ]; then
        print_message "$YELLOW" "  Skipping '$target_path' for '$display_name': Symlink points to '$current_link_target', not expected '$expected_link_target'."
      fi
      return 0 
    fi
  else
    print_message "$RED" "Unknown action '$action' in process_single_item."
    return 1
  fi
}

# seed_file_if_missing()
# Seed a file from source to target if the target doesn't exist
# Arguments:
#   $1 - action: "link" or "unlink"
#   $2 - source_path: Path to the source file
#   $3 - target_path: Path where the file should be seeded
#   $4 - display_name: Human-readable name for the file
# Returns: 0 on success, 1 on failure
seed_file_if_missing() {
  local action="$1"
  local source_path="$2"
  local target_path="$3"
  local display_name="$4"

  echo -e "${PURPLE}  DEBUG: seed_file_if_missing: action='$action', source='$source_path', target='$target_path', name='$display_name'${NC}"

  if [ "$action" = "link" ]; then
    if [ ! -f "$source_path" ]; then
      print_message "$RED" "  ERROR: Source file '$source_path' for '$display_name' does not exist. Skipping."
      return 1
    fi

    local target_parent_dir
    target_parent_dir=$(dirname "$target_path")
    if [ ! -d "$target_parent_dir" ]; then
      if [ "$QUIET" = false ]; then print_message "$BLUE" "  Creating parent directory '$target_parent_dir' for '$display_name'"; fi
      if ! mkdir -p "$target_parent_dir"; then
        print_message "$RED" "  ERROR: Failed to create parent directory '$target_parent_dir' for '$display_name'."
        return 1
      fi
    fi

    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
      if [ "$QUIET" = false ]; then print_message "$GREEN" "  Preserving existing '$target_path' for '$display_name'."; fi
      return 0
    fi

    if [ "$QUIET" = false ]; then echo -n -e "${CYAN}  Seeding '$source_path' to '$target_path'... ${NC}"; fi
    if cp "$source_path" "$target_path"; then
      if [ "$QUIET" = false ]; then echo -e "${GREEN}✓ Seeded${NC}"; fi
      return 0
    else
      if [ "$QUIET" = false ]; then echo -e "${RED}✗ Seed Failed${NC}"; fi
      print_message "$RED" "  ERROR: Failed to seed '$display_name'."
      return 1
    fi
  elif [ "$action" = "unlink" ]; then
    if [ "$QUIET" = false ]; then print_message "$GRAY" "  Leaving '$target_path' for '$display_name' in place (seeded local config)."; fi
    return 0
  fi

  print_message "$RED" "  ERROR: Unknown action '$action' for '$display_name'."
  return 1
}

# restore_path_from_backup()
# Restore a file or directory from backup to target path
# Arguments:
#   $1 - backup_path: Path to the backup file/directory
#   $2 - target_path: Path where the backup should be restored
# Returns: 0 on success (or if backup doesn't exist)
restore_path_from_backup() {
  local backup_path="$1"
  local target_path="$2"

  if [ ! -e "$backup_path" ]; then
    return 0
  fi

  if [ -d "$backup_path" ]; then
    mkdir -p "$target_path"
    cp -RL "$backup_path/." "$target_path/"
  elif [ ! -e "$target_path" ]; then
    mkdir -p "$(dirname "$target_path")"
    cp -RL "$backup_path" "$target_path"
  fi
}

# reconcile_cliproxy_runtime()
# Reconcile cliproxy runtime state after backup restoration
# Arguments:
#   $1 - package_dir: Path to the cliproxy package directory
#   $2 - backup_dir: Path to the backup directory for restoration
# Returns: 0 always
reconcile_cliproxy_runtime() {
  local package_dir="$1"
  local backup_dir="$2"

  mkdir -p "$package_dir/auths" "$package_dir/logs"

  restore_path_from_backup "$backup_dir/config.yaml" "$package_dir/config.yaml"
  restore_path_from_backup "$backup_dir/auths" "$package_dir/auths"
  restore_path_from_backup "$backup_dir/logs" "$package_dir/logs"

  if [ ! -f "$package_dir/config.yaml" ]; then
    cp "$package_dir/config.yaml.example" "$package_dir/config.yaml"
  fi

  if [ -f "$package_dir/config.yaml" ]; then
    chmod 600 "$package_dir/config.yaml"
  fi
}

# reconcile_omp_runtime()
# Reconcile OMP runtime state after backup restoration
# Arguments:
#   $1 - package_dir: Path to the OMP package directory
#   $2 - backup_dir: Path to the backup directory for restoration
# Returns: 0 always
reconcile_omp_runtime() {
  local package_dir="$1"
  local backup_dir="$2"

  mkdir -p "$package_dir/agent" "$package_dir/logs"

  restore_path_from_backup "$backup_dir/agent/agent.db" "$package_dir/agent/agent.db"
  restore_path_from_backup "$backup_dir/agent/agent.db-shm" "$package_dir/agent/agent.db-shm"
  restore_path_from_backup "$backup_dir/agent/agent.db-wal" "$package_dir/agent/agent.db-wal"
  restore_path_from_backup "$backup_dir/agent/history.db" "$package_dir/agent/history.db"
  restore_path_from_backup "$backup_dir/agent/history.db-shm" "$package_dir/agent/history.db-shm"
  restore_path_from_backup "$backup_dir/agent/history.db-wal" "$package_dir/agent/history.db-wal"
  restore_path_from_backup "$backup_dir/agent/models.db" "$package_dir/agent/models.db"
  restore_path_from_backup "$backup_dir/agent/models.db-shm" "$package_dir/agent/models.db-shm"
  restore_path_from_backup "$backup_dir/agent/models.db-wal" "$package_dir/agent/models.db-wal"
  restore_path_from_backup "$backup_dir/agent/sessions" "$package_dir/agent/sessions"
  restore_path_from_backup "$backup_dir/agent/terminal-sessions" "$package_dir/agent/terminal-sessions"
  restore_path_from_backup "$backup_dir/gpu_cache.json" "$package_dir/gpu_cache.json"
  restore_path_from_backup "$backup_dir/logs" "$package_dir/logs"

  patch_global_omp_install "$package_dir"
}

# patch_global_omp_install()
# Apply OMP compatibility patch to the global installation
# Arguments:
#   $1 - package_dir: Path to the OMP package directory
# Returns: 0 always
patch_global_omp_install() {
  local package_dir="$1"
  local patch_script="$package_dir/scripts/patch-global-omp.mjs"

  if [ ! -f "$patch_script" ]; then
    if [ "$QUIET" = false ]; then print_message "$YELLOW" "  OMP compatibility patch script not found at '$patch_script'."; fi
    return 0
  fi

  ensure_bun_bin_on_path
  if ! command_exists bun; then
    if [ "$QUIET" = false ]; then print_message "$YELLOW" "  Bun not found, skipping OMP compatibility patch."; fi
    return 0
  fi

  if [ "$QUIET" = false ]; then
    print_message "$BLUE" "  Applying OMP compatibility patch to the active global install..."
    echo
    if bun "$patch_script"; then
      print_message "$GREEN" "    OMP compatibility patch applied."
    else
      print_message "$YELLOW" "    Warning: failed to apply the OMP compatibility patch. Run 'bun ~/.omp/scripts/patch-global-omp.mjs' after installing OMP."
    fi
    return 0
  fi

  local patch_out patch_ec
  set +e
  patch_out=$(bun "$patch_script" 2>&1)
  patch_ec=$?
  set -e
  if [ $patch_ec -eq 0 ]; then
    return 0
  fi

  print_message "$YELLOW" "  Warning: failed to apply the OMP compatibility patch. Run 'bun ~/.omp/scripts/patch-global-omp.mjs' after installing OMP."
  print_message "$GRAY" "    Output: $patch_out"
  return 0
}
