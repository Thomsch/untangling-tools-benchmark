#!/usr/bin/env bats

setup() {
    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
}

@test "retrieving sourcepath with jq" {
    sourcepath=$(jq --raw-output '[.[] | .javac_switches.sourcepath] | add' "$DIR/javac.json")
    [ $sourcepath = "/absolute/path/to/moved/source/filesA:/absolute/path/to/moved/source/filesB:" ]
}

@test "retrieving classpath with jq" {
    classpath=$(jq --raw-output '[.[] | .javac_switches.classpath] | add' "$DIR/javac.json")
    [ $classpath = "/absolute/path/to/compiled/classes:/absolute/path/to/maven/libA:/absolute/path/to/maven/libB:/absolute/path/to/compiled/classes:/absolute/path/to/maven/libC:/absolute/path/to/maven/libD:" ]
}