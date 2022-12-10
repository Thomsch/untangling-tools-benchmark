import os
import sys
import json
import glob

# Retrieves changed lines for SmartCommit results.

# Exports line changed from smartcommit group
# # #G1.csv
# class, line
# class, line
# class, line

# #G2.csv
# class, line
# class, line
# class, line

def list_json_files(dir):
    """
    " Returns the JSON files contained in the specific directory.
    """
    return glob.glob(os.path.join(dir, '*.json'))

def main():
    args = sys.argv[1:]

    if len(args) != 1:
        print("usage: export_group.py <path/to/root/results>")
        exit(1)
    
    result_dir = args[0]
    diff_dir = os.path.join(result_dir, 'diffs')
    groups_dir = os.path.join(result_dir, 'generated_groups')

    diff_data = {}

    # Load diffs
    for diff_path in list_json_files(diff_dir):
        with open(diff_path, 'r') as diff_file:
            data = json.load(diff_file)
            class_path = data['currentRelativePath']
            file_id = data['fileID']

            hunks = {}
            diff_data[file_id] = hunks

            # Save data for each hunk
            for hunk_data in data['diffHunksMap'].values():
                hunk_id = hunk_data['diffHunkID']
                startLine = hunk_data['currentHunk']['startLine']
                endLine = hunk_data['currentHunk']['endLine']
                
                hunks[hunk_id] = (class_path, startLine, endLine)
                

    # Print CSV for each group
    for group_path in list_json_files(groups_dir):
        print(group_path)
        with open(group_path, 'r') as group_file:
            data = json.load(group_file)

            hunks = data['diffHunkIDs']

            for hunk in hunks:
                file_id, hunk_id = hunk.split(':')
                class_path, start_line, end_line = diff_data[file_id][hunk_id]

                for line in range(start_line, end_line + 1):
                    print(f"{class_path},{line}")

if __name__ == "__main__":
    main()