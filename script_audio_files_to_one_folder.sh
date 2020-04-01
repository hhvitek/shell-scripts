#!/bin/bash

# 1] Process $INPUT_FOLDER folder structure and look for any audio files (mp3, m4a, ...)
# 2] Rename file - removes unwanted characters
# 3] Move file into $OUTPUT_FOLDER folder. If a targeted folder does not exist,
#    it is auto-created using mkdir command

INPUT_FOLDER="./Allie"
OUTPUT_FOLDER="./Allie-OUTPUT"

AUDIO_FILE_EXTENSIONS='mp3,m4a,mpa,ogg, wma,aac,    wav,flac,aiff,alac'

# man(7)
# To include a literal ']' in the list, make it the first character
#        (following a possible '^').  To include a literal '-', make it the
#        first or last character, or the second endpoint of a range.  To use a
#        literal '-' as the first endpoint of a range, enclose it in "[." and
#        ".]"  to make it a collating element (see below).  With the exception
#        of these and some combinations using '[' (see next paragraphs), all
#        other special characters, including '\', lose their special
#        significance within a bracket expression.
AUDIO_FILE_SAFE_CHARACTERS_REGEX='][()_.[:blank:][:alnum:]-'


##################################################
# Trims input string...
# Arguments:
#   $1 input string
# Returns:
#   0 if elements is present in an array, otherwise non-zero value.
#   prints (echo) trimmed string
##################################################
function trim {
    if [ "$#" -ne 1 ]; then
        echo $#
        echo "Invalid arguments!" >&2
        return -1
    fi

    local input="$1"
    input=$( sed -r 's/^ *| *$//g' <<< "$input")

    echo "$input"

    return 0
}

###################################################
# split() function expected string delimited by for example space or ","
# Arguments:
#   $1 input string
#   $2 delimiter
# Returns:
#   prints result
###################################################
function get_array_from_string {
    if [ "$#" -ne 2 ]; then
        echo "Invalid arguments!" >&2
        return -1
    fi

    local input="$1"
    local delimiter="$2"

    # string to array by delimiter ","
    local IFS_BACKUP="$IFS"
    IFS="$delimiter" # delimiter
    local output_arr=( $input ) # do not use quotes... that's the trick
    #read -a suffixes_arr <<< "${suffixes}" alternative
    IFS="$IFS_BACKUP" # restore IFS

    echo "${output_arr[*]}"
    return 0
}

##################################################
# Does an array contains an elements?
# Arguments:
#   $1 string - suffixes separated by "," ... "mp3,m4a" ... it is trimmed so "mp3, m4a" is valid option as well
#   $2 string - suffix to look for ... "mp3"
# Returns:
#   0 if elements is present in an array, otherwise non-zero value.
##################################################
function contains {
    if [ "$#" -ne 2 ]; then
        echo "Invalid arguments!" >&2
        return -1
    fi

    local suffixes="$1"
    local element="$2"

    suffixes_arr=( $( get_array_from_string "$suffixes" ",") )

    for suffix in "${suffixes_arr[@]}"; do
        # trim -r for "|"
        suffix="$( trim "$suffix")"

        if [ "$suffix" = "$element" ]; then
            return 0
        fi
    done

    return 1
}

#####################################################
# * Takes string (name of a file) and strips any character (regex) not included
#   in the global variable $AUDIO_FILE_SAFE_CHARACTERS_REGEX
# * Trims string and replaces blanks with underscore "_"
# Arguments:
#   Input string
# Returns:
#   0 on success, non-zero on fail
#   prints (echo) result of stdout
#####################################################
function process_filename {
    if [ "$#" -ne 1 ]; then
        echo "Invalid arguments!" >&2
        return -1
    fi

    local filename="$1"

    filename=$(
        echo "$filename" |
        sed "s/[^${AUDIO_FILE_SAFE_CHARACTERS_REGEX}]/ /g" |
        tr -s '[[:space:]]'
    )

    filename=$(
        trim "$filename" | sed 's/[[:space:]]/_/g'
    )

#   filename="$( sed "s/[^${AUDIO_FILE_SAFE_CHARACTERS_REGEX}]/ /g" <<< "$filename")"
#   filename="$( tr -s '[[:space:]]' <<< "$filename" )"
#   filename="$( trim "$filename" )"

    echo "$filename"
    return 0
}

###########################################################
# Process file - relative/absolute path
# 1] Process @see function for filename processing
# 2] Copy file into $FOLDER_OUTPUT under the new processed name.
###########################################################
function process_file {
    if [ "$#" -ne 1 ]; then
        echo "Invalid arguments!" >&2
        return -1
    fi

    local filename="$1"

    basename="$(basename -- "$filename")"

    name="${basename%.*}"
    extension="${basename##*.}"

    new_name="$( process_filename "$name")"

    mkdir -p -- "$OUTPUT_FOLDER"

    new_filename="${OUTPUT_FOLDER}/${new_name}.${extension}"
    cp -- "$filename" "$new_filename"

    echo "Processed: ${new_filename:0:80}..."
}

###################################################################
# Executes program 1st attempt
# For-loop using bash filename-expansion(*)
# Issue here is not recursive
#   * shopt -s globstar maks "**" recursive search


#real    3m58.760s
#user    0m42.310s
#sys     1m36.166s
###################################################################
function run_standard {

    shopt -s globstar
    for filename in $INPUT_FOLDER/**/*.*; do
        if [ ! -f "$filename" ]; then
            continue # file exists or ignore
        fi

        file_extension="${filename##*.}"

        if contains "$AUDIO_FILE_EXTENSIONS" "$file_extension"; then
            process_file "$filename"
        fi
    done
}

###################################################################
# Executes program 2nd attempt - using find utility
# issue here is for-loop and find utility breaks if file names contain whitespace
#   * change find's output delimiter to NULL
#   * read find's output using read utility with appropriate parameters

#real    2m5.724s
#user    0m27.071s
#sys     1m1.740s
###################################################################
function run_using_find {
    extensions_arr=( $( get_array_from_string "$AUDIO_FILE_EXTENSIONS" ",") )

    for extension in "${extensions_arr[@]}"; do

        # -r prevents interpretation of \ escapes
        # -d NULL instead of newline
        # -print0 NULL instead of newline
        find "$INPUT_FOLDER" -type f -name "*.$extension" -print0 |
            while IFS= read -r -d '' filename; do
                if [ ! -f "$filename" ]; then
                    continue # file exists or ignore
                fi

                process_file "$filename"
            done

    done
}


echo "---- STARTING ----"

run_using_find
#run_standard

echo "---- FINISHED ----"