#!/bin/bash
#
# Retrieves the minimal bug-fixing changes for a Defect4J bug.
#
# Saves the results in a table:
# class     | line changed
# Foo.java  | 3
# Foo.java  | 5
# Bar.java  | 230
# Bar.java  | 231
# Bar.java  | 232
#

#https://stackoverflow.com/questions/8259851/using-git-diff-how-can-i-get-added-and-modified-lines-numbers
diff-lines() {
    local path=
    local line=
    while read; do
        esc=$'\033'
        if [[ $REPLY =~ ---\ (a/)?.* ]]; then
            continue
        elif [[ $REPLY =~ \+\+\+\ (b/)?([^[:blank:]$esc]+).* ]]; then
            path=${BASH_REMATCH[2]}
        elif [[ $REPLY =~ @@\ -[0-9]+(,[0-9]+)?\ \+([0-9]+)(,[0-9]+)?\ @@.* ]]; then
            line=${BASH_REMATCH[2]}
        elif [[ $REPLY =~ ^($esc\[[0-9;]*m)*([\ +-]) ]]; then
            # echo "$line:$REPLY"
            if [[ ${BASH_REMATCH[2]} == - || ${BASH_REMATCH[2]} == + ]]; then
                echo "$path,$line"
            fi

            if [[ ${BASH_REMATCH[2]} != - ]]; then
                ((line++))
            fi

        fi
    done
}

# Ground truth:
project="Lang"
vid="1"
patch="/Users/thomas/Workplace/defects4j/framework/projects/$project/patches/$vid.src.patch"
# Show patch
# cat $defects4j_framework/projects/$project/patches/$vid.src.patch
cat  $patch | diff-lines | uniq
# Diff-lines is probably not getting the right line numbers (new rather than old file (vn to vbug)).
