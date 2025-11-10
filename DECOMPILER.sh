#!/bin/bash

## This is the pseudo-decompiler, where the main monolithic script will get functions separated by annotations into a different file
## This will generate split files in a folder, as well as a head file, relative to current working directory.
## Make sure you're in the right directory before running this tool!

# Required prefix to register as section
readonly PREFIX="#--" # General
# For head file processing
readonly SRC_SYMBOL="|"    # Source/import something
readonly EXEC_SYMBOL="!"   # Execute directly
readonly EVAL_SYMBOL=":"   # Evaluate or interpret (e.g. inline code)
readonly RUN_SYMBOL=">"    # Run or forward
readonly IGNORE_SYMBOL="-" # Probably just cosmetic, skip this

HEADFILE="./_head.sh"
SPLITFILEDIR="./SRC"
func_lists=()

# Misc. log tooling
logdo() {
    echo -n "${1}..." 
}
ok() { 
    if [[ -z $1 ]]; then 
        echo "ok" 
    else
        echo "$1"
    fi 
}

# Input file (Don't assume paths)
INPUT_FILE=$1

if [[ -z "$INPUT_FILE" ]]; then
    echo "Error: Input file not provided."
    exit 1
fi

verify_file() {
    is_script() {
        logdo "Checking for signs of shell script"
        if [[ $INPUT_FILE == "*.sh" ]] || [[ -n "${INPUT_CONTENT[$i]}" && "${INPUT_CONTENT[$i]}" == "\#!*" ]]; then
            ok
        else
            ok "Not Found"
            echo "Unable to verify! Make sure that your file is either starts with a #! or has '.sh' extension."
            exit 1
        fi
    }

    has_any_prefix() {
        hasPrefix=0
        for line in ${content_array}; do
            if [[ "$line" == $PREFIX* || "$line" == $NOSOURCE_PREFIX* ]]; then
                hasPrefix=1
                break
            fi
        done

        if [[ $hasPrefix -ne 1 ]]; then
            echo "Cannot found any annotations! This is required to split the files accordingly."
        fi
    }

    is_script
    has_any_prefix
}

echo "Using $(realpath $INPUT_FILE)."

# Newlinw separated array of script contents
INPUT_CONTENT=()
while IFS= read -r line; do
    INPUT_CONTENT+=("$line")
done < "$INPUT_FILE"

# Find the first alphabet part of the commented line
get_function_name() {
    local line="$1"
    echo "${line#"${PREFIX}"?}"
}

get_type_token() {
    local line="$1"

    line="${line#"${PREFIX}"}"
    echo "${line:0:1}"
}

shebang_line=""

get_shebang() {
    local content_array=("$@")

    # Look for shebang in first 2 lines
    for i in 0 1; do
        if [[ -n "${content_array[$i]}" && "${content_array[$i]}" == "\#!*" ]]; then
            shebang_line="${content_array[$i]}"
            break
        fi
    done
}

create_srcs() {
    mkdir -p "$SPLITFILEDIR"
    write_srcs
}

write_srcs() {
    for line in "${INPUT_CONTENT[@]}"; do
        if [[ "$line" == $PREFIX* ]] && [[ $(get_type_token $line) != "${IGNORE_SYMBOL}" ]]; then
            
            # Close previous function file if it exists
            [[ -n "$output_file" ]] && exec 3>&-

            # Make the previous file executable
            chmod +x "$output_file"

            # Start new function
            function_name=$(get_function_name "$line")

            # Force exit on END tag
            if [[ "$function_name" == "END" ]]; then
                break
            fi

            output_file="${SPLITFILEDIR}/${function_name}.sh"
            echo "Processing function: $function_name"

            # Open new output file
            exec 3> "$output_file"

            cmd=""
            typeToken="$(get_type_token "$line")"

            case "$typeToken" in
                $SRC_SYMBOL)
                    cmd="source "
                    ;;
                    
                $EXEC_SYMBOL)
                    cmd="exec "
                    ;;
                
                $EVAL_SYMBOL)
                    cmd="eval "
                    ;;

                $RUN_SYMBOL)
                    cmd=""
                    ;;

                *)
                    echo "Unknown symbolic annotation flag ${typeToken}, defaulting to run."
                    cmd=""
                    ;;
            esac

            func_lists+=("${sourceable}${output_file}")
        elif [[ -n "$output_file" ]]; then
            # Write line to current function file
            echo "$line" >&3
        fi
    done

    # Close the last output file
    [[ -n "$output_file" ]] && exec 3>&-
}


create_headfile() {
    get_shebang
    if [[ "$shebang_line" != "" ]]; then
        echo "$shebang_line" >> "$HEADFILE"
    fi

    echo "${PREFIX} sourceable.list" >> "$HEADFILE"
    for functions in "${func_lists[@]}"; do
        echo "$functions" >> "$HEADFILE"
    done    
    echo "${PREFIX} sourceable.list END" >> "$HEADFILE"

    chmod +x $HEADFILE
}

update_headfile() {
    # Only replace the source lists

    # Preload file to mem
    HEAD_DATAS=()
    while IFS= read -r line; do
        HEAD_DATAS+=("$line")
    done < "$HEADFILE"

    # Find range to remove
    rangeX=-1; rangeY=-1
    for ((i=0; i < ${#HEAD_DATAS[@]}; i++)); do
        if [[ "${HEAD_DATAS[$i]}" == "${PREFIX} sourceable.list" ]]; then
            rangeX="$i"
        elif [[ "${HEAD_DATAS[$i]}" == "${PREFIX} sourceable.list END" ]]; then
            rangeY=$i
            break # Already done, no more stuff needed to be done within loop
        fi
    done

    # Remove the items within the range (inclusive)
    if [[ $rangeX -ge 0 && $rangeY -gt $rangeX ]]; then
        HEAD_DATAS=("${HEAD_DATAS[@]:0:$rangeX}" "${HEAD_DATAS[@]:$((rangeY + 1))}")
    else
        echo "Unable to determine bounds to update the head file! exiting."
        exit 1
    fi

    if [[ ${#func_lists[@]} -gt 0 ]]; then
        # Create new section array
        new_section=(
            "${PREFIX} sourceable.list"
            "${func_lists[@]}"
            "${PREFIX} sourceable.list END"
        )

        # Insert into HEAD_DATAS at position rangeX
        HEAD_DATAS=(
            "${HEAD_DATAS[@]:0:$rangeX}"
            "${new_section[@]}"
            "${HEAD_DATAS[@]:$rangeX}"
        )
    else
        echo "Source file is empty, so will the head file!"
    fi    

    if [[ ${#HEAD_DATAS[@]} -gt 0 ]]; then
        # Clean up file
        : > "$HEADFILE"

        # Fill the new data to file
        for data in "${HEAD_DATAS[@]}"; do
            echo "$data" >> "$HEADFILE"
        done
    fi
}

if [[ ! -d "$SPLITFILEDIR" ]]; then
    create_srcs
else 
    write_srcs
fi

# Initialize headfile with shebang
if [[ ! -f "$HEADFILE" ]]; then
    create_headfile
else
    update_headfile
fi

