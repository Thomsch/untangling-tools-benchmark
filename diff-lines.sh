#!/bin/bash
#https://stackoverflow.com/questions/8259851/using-git-diff-how-can-i-get-added-and-modified-lines-numbers

diff-lines() {
    local output_file="out/ground_truth.csv"
    rm -f $output_file

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
            echo "$line:$REPLY"
            if [[ ${BASH_REMATCH[2]} == - || ${BASH_REMATCH[2]} == + ]]; then
                echo "$path,$line" >> $output_file
            fi

            if [[ ${BASH_REMATCH[2]} != - ]]; then
                ((line++))
            fi

        fi
    done

    tmp=$(mktemp)
    uniq $output_file "$tmp"
    cp -f "$tmp" $output_file
}

diff-lines