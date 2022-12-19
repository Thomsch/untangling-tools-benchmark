#!/bin/bash

REPO="$1/.git"

if [ ! -d "$REPO" ] 
then
    echo "Directory $REPO DOES NOT exists." 
    exit 1
fi

# Git diff -U0 on top of Vn +  Pipe output to changed_lines.py
git --git-dir="$REPO" diff -U0 HEAD^ HEAD | python3 parse_patch.py