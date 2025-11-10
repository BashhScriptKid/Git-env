#!/bin/bash

# This is the pseudo-decompiler, where the main git-env script will get functions separated by categories into a different file

# Required prefix to register as section
readonly PREFIX="#--|"

# Input file (Don't assume paths)
INPUT_FILE=$1

if [[ -z "$INPUT_FILE" ]]; then
    echo "Error: Input file not provided."
    exit 1
fi

# Find the first alphabet part of the commented line
get_function_name() {
    local line="$1"
    echo "${line#"${PREFIX}"}"
}


main_script_line_looper() {
    local line
    local function_name=""
    local output_file=""
    local INPUT_FILE="$1"
    local folder="SRC"

    # Convert to absolute path before changing directories
    INPUT_FILE="$(realpath "$INPUT_FILE")"

    if [[ ! -z $folder ]]; then
        if [[ ! -d "$folder" ]]; then
            mkdir "$folder"
        fi
        cd "$folder"
    fi

    headFile="../_head.sh"

    # Empty head file if already polulated
    if [[ -f $headFile ]]; then
        : > $headFile
    fi


    while IFS= read -r line; do
        if [[ $line == $PREFIX* ]]; then
            # Close previous function file if it exists
            [[ -n "$output_file" ]] && exec 3>&-

            # Make the previous file executable
            chmod +x "$output_file"

            # Start new function
            function_name=$(get_function_name "$line")

            # Force exit on END tag
            if [[ $function_name == "END" ]]; then
                break
            fi

            output_file="$function_name.sh"
            echo "Processing function: $function_name"

            # Open new output file and write the function header
            exec 3> "$output_file"

            # Push the function name to a head file
            funcPath="${folder}/${output_file}"

            echo "source $funcPath" >> "$headFile" # Since it's currently in the ${folder} directory.

        elif [[ -n "$output_file" ]]; then
            # Write line to current function file
            echo "$line" >&3
        fi
    done < "$INPUT_FILE"

    if [[ ! -z $folder ]]; then
        cd ".."
    fi


    # error if no functions found
    if [[ -z $output_file ]]; then
        echo "Error: No 'decompilation' tags are defined in input!"
        exit 1
    fi

    # Close the last output file
    [[ -n "$output_file" ]] && exec 3>&-

    # Make head file executable
    if [[ -f $headFile ]]; then
        chmod +x $headFile
    fi
}


echo "Running."
main_script_line_looper "$INPUT_FILE"
