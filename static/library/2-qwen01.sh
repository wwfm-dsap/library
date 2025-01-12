#!/bin/bash

# Input file (passed as an argument)
INPUT_XLSX="$1"

# Ensure the input file is provided
if [ -z "$INPUT_XLSX" ]; then
    echo "Usage: ./2.sh <input_xlsx_file>"
    exit 1
fi

# Check if the input file exists
if [ ! -f "$INPUT_XLSX" ]; then
    echo "File $INPUT_XLSX does not exist."
    exit 1
fi

# Python script for JSON generation
PYTHON_SCRIPT="convert_xlsx_to_json.py"

# Create the Python script
cat << EOF > "$PYTHON_SCRIPT"
import os
import sys
import json
from collections import defaultdict
from openpyxl import load_workbook

# Load the workbook
try:
    wb = load_workbook(INPUT_XLSX, data_only=True)
except Exception as e:
    print(f"Error loading XLSX file: {e}")
    sys.exit(1)

# Dictionary to map all countries to their respective JSON files
countries_data = {
    "countries": []
}

# Helper function to zero out UID blocks
def zero_out_uid(uid, level):
    if not uid:
        return None
    parts = uid.split('-')
    for i in range(level, len(parts)):
        parts[i] = '0' * len(parts[i])
    return '-'.join(parts)

# Function to copy a node to the pruned hierarchy if needed
def copy_if_needed(old_node):
    new_node = {}
    if 'has_y' in old_node and old_node['has_y']:
        new_node['name'] = old_node['name']
        if 'uid' in old_node:
            new_node['uid'] = old_node['uid']
        if 'level2' in old_node:
            new_node['level2'] = []
            for child in old_node['level2']:
                copied_child = copy_if_needed(child)
                if copied_child:
                    new_node['level2'].append(copied_child)
    return new_node if new_node else None

# Process each sheet (tab) in the workbook
for sheet in wb.worksheets:
    # Use the sheet name as the country code
    country_code = sheet.title.lower()

    # Initialize the data structure for the JSON
    sheet_data = {
        "level1": []
    }

    # Build the hierarchy
    level_hierarchy = defaultdict(lambda: defaultdict(lambda: defaultdict(lambda: defaultdict(list))))

    for row in sheet.iter_rows(min_row=2):
        # Read columns A-F (first six columns)
        name1 = row[0].value.strip() if row[0].value else None
        name2 = row[1].value.strip() if row[1].value else None
        name3 = row[2].value.strip() if row[2].value else None
        name4 = row[3].value.strip() if row[3].value else None
        name5 = row[4].value.strip() if row[4].value else None
        uid = row[5].value.strip() if row[5].value else None
        has_y = row[6].value == 'y'  # Check column G for 'y'

        # Build hierarchy, marking 'has_y' where applicable
        if name1:
            current_level1 = level_hierarchy[name1]
            if "uid" not in current_level1:
                current_level1["uid"] = zero_out_uid(uid, 2)  # Zero out from Level 2 onward
            current_level1["has_y"] = has_y or ('has_y' in current_level1 and current_level1['has_y'])
        if name2:
            current_level2 = current_level1[name2]
            if "uid" not in current_level2:
                current_level2["uid"] = zero_out_uid(uid, 3)  # Zero out from Level 3 onward
            current_level2["has_y"] = has_y or ('has_y' in current_level2 and current_level2['has_y'])
        if name3:
            current_level3 = current_level2[name3]
            if "uid" not in current_level3:
                current_level3["uid"] = zero_out_uid(uid, 4)  # Zero out from Level 4 onward
            current_level3["has_y"] = has_y or ('has_y' in current_level3 and current_level3['has_y'])
        if name4:
            if not isinstance(current_level3[name4], dict):
                current_level3[name4] = {"level5": []}
            current_level4 = current_level3[name4]
            if "uid" not in current_level4:
                current_level4["uid"] = zero_out_uid(uid, 5)  # Zero out from Level 5 onward
            current_level4["has_y"] = has_y or ('has_y' in current_level4 and current_level4['has_y'])
        if name5:
            current_level4["level5"].append({
                "name": name5,
                "uid": uid,  # Full UID for Level 5
                "has_y": has_y
            })

    # Convert defaultdict to a regular dict for JSON serialization
    level1_items = []
    for name1, level2 in level_hierarchy.items():
        level1_item = {
            "name": name1,
            "uid": level2.pop("uid", None),
            "level2": []
        }
        for name2, level3 in level2.items():
            level2_item = {
                "name": name2,
                "uid": level3.pop("uid", None),
                "level3": []
            }
            for name3, level4 in level3.items():
                level3_item = {
                    "name": name3,
                    "uid": level4.pop("uid", None),
                    "level4": []
                }
                for name4, level5 in level4.items():
                    level4_item = {
                        "name": name4,
                        "uid": level5.pop("uid", None),
                        "level5": level5.pop("level5", [])
                    }
                    level3_item["level4"].append(level4_item)
                level2_item["level3"].append(level3_item)
            level1_item["level2"].append(level2_item)
        level1_items.append(level1_item)

    # Prune the hierarchy
    pruned_hierarchy = []
    for item in level1_items:
        pruned_item = copy_if_needed(item)
        if pruned_item:
            pruned_hierarchy.append(pruned_item)

    # Write JSON for the current sheet
    json_filename = f"{country_code}.json"
    with open(json_filename, "w") as json_file:
        json.dump({"level1": pruned_hierarchy}, json_file, indent=2)

    # Add to the mapping in data.json
    countries_data["countries"].append({
        "name": country_code,
        "filename": json_filename
    })

# Sort countries alphabetically by name before writing to data.json
sorted_countries = sorted(countries_data["countries"], key=lambda x: x["name"])

# Write the mapping to data.json with sorted countries
with open("data.json", "w") as data_file:
    json.dump({"countries": sorted_countries}, data_file, indent=2)

print("JSON files have been created for each tab. data.json has been updated with sorted countries.")

# Run the Python script
python3 "$PYTHON_SCRIPT"

# Clean up
rm "$PYTHON_SCRIPT"

echo "JSON generation completed."
