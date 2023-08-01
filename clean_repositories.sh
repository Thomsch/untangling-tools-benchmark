#!/bin/bash
# Cleans this repository and Flexeme's for the double-blind paper submission.

set -o errexit    # Exit immediately if a command exits with a non-zero status
set -o nounset    # Exit if script tries to use an uninitialized variable
set -o pipefail   # Produce a failure status if any command in the pipeline fails

if [ $# -ne 1 ] ; then
    echo 'usage: clean_repositories.sh <out_dir>'
    exit 1
fi


export out_dir="$1" # The directory where to put cleaned repositories


mkdir -p "$out_dir"

# Clone repositories
# git clone --depth 1 https://github.com/Thomsch/untangling-tools-benchmark "$out_dir/untangling-tools-benchmark"
# git clone --depth 1 https://github.com/Thomsch/flexeme "$out_dir/flexeme"

# Delete .git .github .vscode folders in both repositories
clean_repo() {
    repo_dir="$1"
    rm -rf "$repo_dir/.git"
    rm -rf "$repo_dir/.github"
    rm -rf "$repo_dir/.vscode"

}

clean_repo "$out_dir/untangling-tools-benchmark"
clean_repo "$out_dir/flexeme"

# Replace Github user ids thomsch, thanhdang2712, rjust, mernst with 'anonymous'
find "$out_dir" -type f -print0 | xargs -0 perl -pi -e 's/thomsch/anonymous/gi'
find "$out_dir" -type f -print0 | xargs -0 perl -pi -e 's/thanhdang2712/anonymous/gi'
find "$out_dir" -type f -print0 | xargs -0 perl -pi -e 's/rjust/anonymous/gi'
find "$out_dir" -type f -print0 | xargs -0 perl -pi -e 's/mernst/anonymous/gi'

find "$out_dir" -type f -print0 | xargs -0 perl -pi -e 's%anonymous/defects4j%rjust/defects4j%gi' # if we anonymize legitimate link to defects4j, it is suspicious.

# Replace first and or last names with 'Anonymous'
# Names: Thomas Schweizer, Thanh Dang, Rene Just, Mike Ernst
# Refactor the code to use a function that takes a full name as a parameter

replace_name() {
    full_name="$1"
    first_name=$(echo "$full_name" | cut -d' ' -f1)
    last_name=$(echo "$full_name" | cut -d' ' -f2)

    find "$out_dir" -type f -print0 | xargs -0 perl -pi -e "s/$first_name/Anonymous/gi"
    find "$out_dir" -type f -print0 | xargs -0 perl -pi -e "s/$last_name/Anonymous/gi"
    find "$out_dir" -type f -print0 | xargs -0 perl -pi -e "s/$full_name/Anonymous/gi"
}

replace_name "Thomas Schweizer"
replace_name "Thanh Dang"
replace_name "Rene Just"
replace_name "Michael Ernst"
replace_name "Mike Ernst"


# Replace school ids tschweiz, thanh, rjust, mernst with 'anonymous'
find "$out_dir" -type f -print0 | xargs -0 perl -pi -e 's/tschweiz/anonymous/gi'
find "$out_dir" -type f -print0 | xargs -0 perl -pi -e 's/thanh/anonymous/gi'
find "$out_dir" -type f -print0 | xargs -0 perl -pi -e 's/rjust/anonymous/gi'
find "$out_dir" -type f -print0 | xargs -0 perl -pi -e 's/mernst/anonymous/gi'

find "$out_dir" -type f -print0 | xargs -0 perl -pi -e 's%anonymous/defects4j%rjust/defects4j%gi' # if we anonymize legitimate link to defects4j, it is suspicious.

# Replace school name with 'anonymous'
find "$out_dir" -type f -print0 | xargs -0 perl -pi -e 's/washington/anonymous/gi'
find "$out_dir" -type f -print0 | xargs -0 perl -pi -e 's/cs.washington/anonymous/gi'
# The is no occurence of the school acronym anywhere