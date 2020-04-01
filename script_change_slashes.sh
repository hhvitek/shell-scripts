#!/bin/bash

# Searches for any $FILES files
# Replaces backslash(\) for forwardslash(/)
# C:\Hello\World -> C:/Hello/World

FILES="mod/*/descriptor.mod"

# no quotes around $FILES! in the following for-cycle
#       we need bash-expansion(*)
# if there is no file matched by $FILES variable in the directory,
# executes exactly one times with a file "mod/*/descriptor.mod" ->
# workaround test whether the returned file actually exists

for filename in $FILES; do
    # [ -e "$filename" ] || continue
    if [ ! -e "$filename" ]; then
        echo "Most likely no file found..."
        continue
    fi
    
    echo "Processing: $filename"
    sed -i 's;\\;/;g' "$filename"
    
done

