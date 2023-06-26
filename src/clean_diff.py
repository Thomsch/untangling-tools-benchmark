import os
import sys
from collections import defaultdict
from io import StringIO

import numpy as np
import pandas as pd
from unidiff import PatchedFile, Hunk, PatchSet, LINE_TYPE_CONTEXT, LINE_TYPE_REMOVED, LINE_TYPE_ADDED

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
        if not (
            file.source_file.lower().endswith(".java")
            or file.target_file.lower().endswith(".java")
        ):
            continue
        
        # Remove lines from Hunk if they are invalid
        for hunk in file:
            for line in hunk:
                if line.line_type == LINE_TYPE_CONTEXT:
                    continue
                # TODO: Lines starting with "*" are not always comments.
                elif ignore_comments and (
                    line.value.strip().startswith("/*")
                    or line.value.strip().startswith("*/")
                    or line.value.strip().startswith("//")
                    or line.value.strip().startswith("*")
                ):  
                    line.line_type = LINE_TYPE_CONTEXT
                elif ignore_imports and line.value.strip().startswith("import"):
                    line.line_type = LINE_TYPE_CONTEXT
                # Ignore whitespace only lines.
                elif not line.value.strip():
                    line.line_type = LINE_TYPE_CONTEXT
    return patch

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
                if line.line_type == LINE_TYPE_CONTEXT:  # Ignore context lines.
                    continue
                if line.value == hunk[i+1].value:
                    if hunk[i+1].line_type != LINE_TYPE_CONTEXT and line.line_type != hunk[i+1].line_type:
                        line.line_type = LINE_TYPE_CONTEXT
                        hunk[i+1].line_type = LINE_TYPE_CONTEXT
                        i += 1
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
                if line.line_type == LINE_TYPE_ADDED:
                    additions += 1
                elif line.line_type == LINE_TYPE_REMOVED:
                    deletions += 1
            hunk.source_length = deletions
            hunk.target_length = additions
    return patch

def filter(diff_file, output_file):
    '''
    Filter out comments, import statements, and empty lines from a diff.
    Completely clean the diff files to adhere to the criteria listed in ground truth construction in README.
    '''
    patch = PatchSet.from_filename(diff_file)

    non_code_patch = remove_noncode_lines(patch)
    non_redundant_patch = cancel_out_diff(non_code_patch)
    fixed_info_patch = fix_hunk_info(non_redundant_patch)

    cleaned_patch = []
    for file in fixed_info_patch:
        # Skip non-Java files.
        if not (
            file.source_file.lower().endswith(".java")
            or file.target_file.lower().endswith(".java")
        ):
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
            else:
                hunk_info = "@@ -%d,%d +%d,%d @@%s\n" % (
                    hunk.source_start, hunk.source_length,
                    hunk.target_start, hunk.target_length,
                    ' ' + hunk.section_header if hunk.section_header else '')
                cleaned_patch.append(hunk_info)
            for line in hunk:
                if not line.line_type == LINE_TYPE_CONTEXT:
                    cleaned_patch.append(str(line))
    with open(output_file, 'w') as file:
        file.writelines(cleaned_patch)

def main():
    nonfix_patch = PatchSet.from_filename("diff/bug_fix.diff")
    filter("diff/bug_fix.diff", "diff/cleaned_bug_fix.diff")
main()