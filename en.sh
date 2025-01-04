#!/bin/bash

# Function to recursively find all UIDs in a JSON structure
extract_uids() {
    jq -r '.. | objects | select(has("uid")) | .uid' "$1"
}

# Create or ensure the 'en' directory exists
mkdir -p "en"
chmod 755 "en"

# Loop through all JSON files in the current directory
for json_file in *.json; do
    # Skip 'data.json'
    if [ "$json_file" != "data.json" ]; then
        # Parse JSON to extract UIDs from all levels
        uids=$(extract_uids "$json_file")

        # For each UID, create a directory if UIDs exist
        if [ -n "$uids" ]; then
            first_uid=""
            while IFS= read -r uid; do
                if [ -z "$first_uid" ]; then
                    first_uid="$uid"
                fi
                mkdir -p "en/$uid"

                # Set permissions for the UID directory
                chmod 755 "en/$uid"

                # Create index.html redirect in each UID directory
                index_path="en/$uid/index.html"
                echo '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0; url=../../alliance_finances/" /></head><body></body></html>' > "$index_path"

                # Change ownership to www-data and set permissions to 644 for the index file
                chown www-data:www-data "$index_path"
                chmod 644 "$index_path"

                # Echo for debugging - check creation of files
                echo "Created: $index_path"
            done <<< "$uids"

            # Create the additional directory with the manually generated UID
            if [ -n "$first_uid" ]; then
                prefix="${first_uid:0:3}"
                new_uid="${prefix}-0000-00000-000000-0000000-00000000"
                mkdir -p "en/$new_uid"

                # Set permissions for the new UID directory
                chmod 755 "en/$new_uid"

                # Create index.html redirect in the new UID directory
                index_path="en/$new_uid/index.html"
                echo '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0; url=../../alliance_finances/" /></head><body></body></html>' > "$index_path"

                # Change ownership to www-data and set permissions to 644 for the index file
                chown www-data:www-data "$index_path"
                chmod 644 "$index_path"

                # Echo for debugging - check creation of files
                echo "Created: $index_path"
            fi
        else
            echo "No UIDs found in $json_file"
        fi
    fi
done

# Inform user to restart Apache
echo "Please restart Apache to ensure new configurations are picked up."
echo "Command to restart Apache on Ubuntu: sudo systemctl restart apache2"
