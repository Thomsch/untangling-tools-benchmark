#!/bin/bash

# Untangle and parse results from Flexeme tool.
export FLEXEME_HOME="/Users/thomas/Workplace/Flexeme"


repository=$1
repository="/tmp/Cli-1/"

commit=$2
commit="b0e1b80b6d4a10a9c9f46539bc4c7a3cce55886e"

sourcepath=$3
sourcepath="src/java"

classpath=$4
classpath="/private/tmp/Cli-1/target/classes:/private/tmp/Cli-1/target/lib/commons-lang/jars/commons-lang-2.1.jar:/private/tmp/Cli-1/target/lib/junit/jars/junit-3.8.1.jar"

flexeme $repository $commit $sourcepath $classpath
