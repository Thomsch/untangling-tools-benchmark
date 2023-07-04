import fileinput
from unidiff import PatchedFile, Hunk, PatchSet, LINE_TYPE_CONTEXT, LINE_TYPE_REMOVED, LINE_TYPE_ADDED
import sys
        
def remove_noncode_lines(patch):
    '''
    This implementation is not optimal, as the unidiff Python package does not have built-in remove method to manupulate the list-like Objects using list comprehensions. etc. The best solution is to use del to completely remove the object from memory space. 
    Yet, I have not found a way to do it using indexing or object references.

    Filter out comments, import statements, and empty lines from a diff by marking them as context lines.

    Args: 
        patch: a PatchSet object to be remove the Java comments, import statements, and whitespaces from.
    Returns:
        The PatchSet Object modified in-place.
    '''
    ignore_comments = True
    ignore_imports = True
    
    for file in patch:
        # Skip non-Java files.
        # lower() is used to catch cases where the extension is in upper case.
        # We need at least one file with the Java extension because a diff can have
        # the following cases:
        #   1. source_file is 'dev/null' and the target_file is
        #      'foo.java' (i.e. 'foo.java' was added)
        # 2. source_file is 'foo.java' and the target_file is
        #      'dev/null' (i.e. 'foo.java' was deleted)
        # 3. source_file is 'foo.java' and the target_file is
        #      'foo.java' (i.e. 'foo.java' was modified)
        # Skip test files. We need at least one version of the file to be a test file to cover addition, deletion,
        # and modification cases.
        if not (
            file.source_file.lower().endswith(".java")
            or file.target_file.lower().endswith(".java")
        ) or is_test_file(file.source_file) or is_test_file(file.target_file):
            file.patch_info = None
            file.source_file = ''
            file.source_timestamp = None
            file.target_file = ''
            file.target_timestamp = None
            file.is_binary_file = False
        # Remove lines from Hunk if they are invalid
        for hunk in file:
            for line in hunk:
                if line.line_type == LINE_TYPE_CONTEXT:
                    continue
                if ignore_comments and (
                    line.value.strip().startswith("/*")
                    or line.value.strip().startswith("*/")
                    or line.value.strip().startswith("//")
                    or line.value.strip().startswith("*")
                ):  
                    line.value = "\n"
                if ignore_imports and line.value.strip().startswith("import"):
                    line.value = "\n"
                if not line.value.strip():
                    line.value = "\n"
    return patch

def is_test_file(filename):
    """
    Returns True if the filename is a filename for tests.

    This implementation currently works for all Defects4J 2.0.0 projects.
    """
    return (
        "/test/" in filename
        or "/tests/" in filename
        or filename.startswith("test/")
        or filename.startswith("tests/")
        or filename.endswith("Test.java")
    )

def cancel_out_diff(patch):
    '''
    Remove pairs of consecutive lines with identical contents but reversed Line Type Indicators
    by creating 1-to-1 mapping of redundant changes (i.e. pair of lines that cancel each other out).
    These lines are both marked as context lines.

    Args: 
        patch: a PatchSet object to be remove redundant changed lines from.
    Returns:
        The PatchSet Object modified in-place.
    '''
    for file in patch:
        for hunk in file:
            i = 0
            while i < len(hunk)-1:
                line = hunk[i]
                next_line = hunk[i+1]
                if line.line_type != LINE_TYPE_CONTEXT and next_line.line_type != LINE_TYPE_CONTEXT:  # Ignore context lines.
                    if line.value.strip() == next_line.value.strip():
                        if line.line_type != next_line.line_type:
                            line.value = '\n'
                            next_line.value = '\n'
                            i += 2     # Skip both lines
                            continue
                i += 1
    return patch

def fix_hunk_info(patch):
    '''
    Repair the hunk metadata on cleaned diff file. The line metadata might be incorrect due to changed lines converted to context lines.
    The hunk metadata is a header for each hunk, containing the info in order: source_start, source_length,
                    target_start, target_length, and section_header
    Args: 
        patch: a PatchSet object with possible erroneous hunk info.
    Returns:
        The PatchSet Object modified in-place.
    '''
    for file in patch:
        for hunk in file:
            additions = 0
            deletions = 0
            for line in hunk:
                if line.line_type == LINE_TYPE_ADDED or line.line_type == LINE_TYPE_CONTEXT:
                    additions += 1
                if line.line_type == LINE_TYPE_REMOVED or line.line_type == LINE_TYPE_CONTEXT:
                    deletions += 1
            hunk.source_length = deletions
            hunk.target_length = additions
    return patch

def filter(patch):
    '''
    Filter out comments, import statements, and empty lines from a diff.
    Completely clean the diff files to adhere to the criteria listed in ground truth construction in README.
    '''
    uncommented_patch = remove_noncode_lines(patch)
    non_redundant_patch = cancel_out_diff(uncommented_patch)
    fixed_info_patch = fix_hunk_info(non_redundant_patch)
    return fixed_info_patch

def clean_diff(diff_file):
    '''
    Remove blank lines and split the hunk accordingly.
    '''
    patch = PatchSet.from_filename(diff_file)
    patch = filter(patch)
    cleaned_patch = []
    for file in patch:
        # Skip null Files
        if not file.patch_info and file.source_file == '' and file.target_file == '':   
            continue
        else:
            cleaned_patch.append('' if file.patch_info is None else str(file.patch_info))
            if not file.is_binary_file and file:
                source = "--- %s%s\n" % (
                    file.source_file,
                    '\t' + file.source_timestamp if file.source_timestamp else '')
                target = "+++ %s%s\n" % (
                    file.target_file,
                    '\t' + file.target_timestamp if file.target_timestamp else '')
            cleaned_patch.append(source)
            cleaned_patch.append(target)
        for hunk in file:
            if hunk.source_length == 0 and hunk.target_length == 0:
                continue
            hunk_features = [hunk.source_start, hunk.source_length,
                hunk.target_start, hunk.target_length, hunk.section_header]
            
            ptr = 0
            while ptr < len(hunk):
                consecutive_lines = []                                                    # List of non-empty, consecutive lines
                if not hunk[ptr].value.strip():                                           # Both are blank lines
                    ptr += 1
                    continue
                else:                                                                     # Construct new hunk
                    while ptr < len(hunk) and hunk[ptr].value.strip():
                        consecutive_lines.append(hunk[ptr])
                        ptr += 1
                    new_hunk_features = hunk_features.copy()
                    new_source_start, new_target_start = None, None
                    additions, deletions = 0, 0
                    if len(consecutive_lines) == 0:
                        continue
                    for line in consecutive_lines:
                        if not new_source_start and line.line_type == LINE_TYPE_REMOVED:
                            new_source_start = line.source_line_no
                        if not new_target_start and line.line_type == LINE_TYPE_ADDED:
                            new_target_start = line.target_line_no
                        if line.line_type in [LINE_TYPE_ADDED, LINE_TYPE_CONTEXT]:
                            additions += 1
                        if line.line_type in [LINE_TYPE_REMOVED, LINE_TYPE_CONTEXT]:
                            deletions += 1
                    new_hunk_features[0] = new_source_start if new_source_start else new_hunk_features[0]
                    new_hunk_features[1] = deletions
                    new_hunk_features[2] = new_target_start if new_target_start else new_hunk_features[2]
                    new_hunk_features[3] = additions
                    new_hunk_info = "@@ -%d,%d +%d,%d @@%s\n" % (
                        new_hunk_features[0], new_hunk_features[1],
                        new_hunk_features[2], new_hunk_features[3],
                        ' ' + new_hunk_features[4] if new_hunk_features[4] else '')
                    cleaned_patch.append(new_hunk_info)
                    for line in consecutive_lines:
                        cleaned_patch.append(str(line))
    with open(diff_file, 'w') as file:
        file.writelines(cleaned_patch)

def clean_source_code(java_file):
    '''
    Filter out comments, import statements, and empty lines from the Java source code.
    Completely clean the source code files to adhere to the criteria listed in ground truth construction in README.
    '''
    with fileinput.FileInput(java_file, inplace=True) as file:
        for line in file:
            if line.strip().startswith('import'):
                continue
            elif line.strip().startswith('#'):
                continue
            elif line.strip().startswith('//'):
                continue
            elif not line.strip():
                continue
            else:
                print(line, end='')

def main():
    args = sys.argv[1:]

    if len(args) != 1:
        print("usage: src/clean_diff.py <filename>")
        sys.exit(1)

    filename = args[0]

    if filename.endswith(".java"):
        with open(filename, 'w') as file:
            file.write(sys.stdin.read())
        clean_source_code(filename)
    if filename.endswith(".diff"):
        with open(filename, 'w') as file:
            file.write(sys.stdin.read())
    clean_diff(filename)
        
if __name__ == "__main__":
    main()
