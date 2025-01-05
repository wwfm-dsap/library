#!/bin/bash

# List of files and folders to keep (including hidden files and this script)
KEEP_FILES=(
    "reset.sh"                # Add this script to the keep list
    "alliance_finances"
    "backup"
    "CHANGELOG.md"
    "CNAME"
    ".htaccess"
    "heatmap.html"
    "COLLABORATE.md"
    "index.html"
    "_theme-docs"
    "_theme-explorer"
    "_theme-wiki"
    ".git"
    ".github"
    ".gitignore"
    ".manifest.json"
    ".nojekyll"
    "1.sh"
    "2.sh"
    "3.sh"
    "*.json"
    "*.log"
    "*.xlsx"
)

# Timestamp format for the backup file
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Define the source and destination for `3.sh` backup
SOURCE_FILE="3.sh"
DESTINATION_FILE="backup/3-$TIMESTAMP.sh"

# Create a temporary file to hold the list of paths to keep
TMP_KEEP_LIST=$(mktemp)

# Populate the temporary file with the paths to keep
for item in "${KEEP_FILES[@]}"; do
    echo "./$item" >> "$TMP_KEEP_LIST"
done

# Debugging: Check the content of TMP_KEEP_LIST
echo "Paths to keep:"
cat "$TMP_KEEP_LIST"

# Remove everything not in the keep list
find . -mindepth 1 -print | grep -Fxvf "$TMP_KEEP_LIST" | while read -r path; do
    # Skip removing any paths that are subdirectories of items in the keep list
    for keep in "${KEEP_FILES[@]}"; do
        if [[ $path == ./$keep* ]]; then
            continue 2
        fi
    done
    echo "Deleting: $path"
    rm -rf "$path"
done

# Clean up the temporary file
rm -f "$TMP_KEEP_LIST"

# Backup `3.sh` if it exists
if [ -f "$SOURCE_FILE" ]; then
    cp "$SOURCE_FILE" "$DESTINATION_FILE"
    echo "Backed up '$SOURCE_FILE' to '$DESTINATION_FILE'."
else
    echo "'$SOURCE_FILE' not found; skipping backup."
fi

# Set permissions to `hbnb:hbnb`, `777`, and make shell scripts executable
for item in "${KEEP_FILES[@]}"; do
    if [ -e "$item" ]; then
        chmod -R 777 "$item"
        chown -R hbnb:hbnb "$item"
    fi
done

# Apply permissions and ownership to the backup file in `backup/`
if [ -f "$DESTINATION_FILE" ]; then
    chmod 777 "$DESTINATION_FILE"
    chown hbnb:hbnb "$DESTINATION_FILE"
    chmod +x "$DESTINATION_FILE"
fi

# Make all shell scripts executable
find . -type f -name "*.sh" -exec chmod +x {} \;

echo "Cleanup, backup, and permissions update completed."

