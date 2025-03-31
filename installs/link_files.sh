#!/usr/bin/env bash

# Function to print status messages
print_status() {
  echo "🔗 $1..."
}

# Get the current directory
currentDir=$(pwd)
stowDir="$currentDir/stow"

# Check if stow directory exists
if [ ! -d "$stowDir" ]; then
  echo "Error: Stow directory not found at $stowDir"
  exit 1
fi

# Check if stow directory is empty
if [ -z "$(ls -A $stowDir)" ]; then
  echo "Error: Stow directory is empty"
  exit 1
fi

print_status "Creating symbolic links"

# Keep track of success and failures
success_count=0
failure_count=0
failed_folders=()

# Loop through each folder in the stow directory
for folder in "$stowDir"/*; do
  if [ -d "$folder" ]; then # Check if it's a directory
    folder_name=$(basename "$folder")
    print_status "Processing $folder_name"

    # Check for existing conflicting files
    conflicts=false
    while IFS= read -r -d '' file; do
      target="$HOME/${file#$folder/}"
      if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "Warning: File already exists: $target"
        conflicts=true
      fi
    done < <(find "$folder" -type f -print0)

    if [ "$conflicts" = true ]; then
      echo "Would you like to backup and replace the existing files for $folder_name? (y/n)"
      read -r response
      if [[ "$response" =~ ^[Yy]$ ]]; then
        # Create backup directory with timestamp
        backup_dir="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)/$folder_name"
        mkdir -p "$backup_dir"

        # Backup existing files
        while IFS= read -r -d '' file; do
          target="$HOME/${file#$folder/}"
          if [ -e "$target" ] && [ ! -L "$target" ]; then
            target_dir="$backup_dir/$(dirname "${file#$folder/}")"
            mkdir -p "$target_dir"
            mv "$target" "$target_dir/"
          fi
        done < <(find "$folder" -type f -print0)
      else
        echo "Skipping $folder_name"
        failure_count=$((failure_count + 1))
        failed_folders+=("$folder_name")
        continue
      fi
    fi

    # Attempt to stow the folder
    if stow --dir="$stowDir" --target="$HOME" "$folder_name" 2>/dev/null; then
      echo "✅ Successfully linked $folder_name"
      success_count=$((success_count + 1))
    else
      echo "❌ Failed to link $folder_name"
      failure_count=$((failure_count + 1))
      failed_folders+=("$folder_name")
    fi
  fi
done

# Print summary
echo
echo "====== Summary ======"
echo "Successfully linked: $success_count folders"
if [ $failure_count -gt 0 ]; then
  echo "Failed to link: $failure_count folders"
  echo "Failed folders:"
  for folder in "${failed_folders[@]}"; do
    echo "- $folder"
  done
fi

if [ -d "$HOME/.dotfiles_backup" ]; then
  echo
  echo "Backups were created in $HOME/.dotfiles_backup"
fi

if [ $failure_count -eq 0 ]; then
  echo "✨ All links created successfully!"
else
  echo "⚠️  Some folders failed to link. Please check the summary above."
  exit 1
fi
