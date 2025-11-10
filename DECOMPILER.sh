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

anyInputToken=($SRC_SYMBOL $EXEC_SYMBOL $EVAL_SYMBOL $RUN_SYMBOL)
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
    [[ ! -f $INPUT_FILE ]] && echo "File does not exist!" && exit 1
    
    is_script() {
        logdo "Checking for signs of shell script"
        
        first_line="${INPUT_CONTENT[0]:-}"
        second_line="${INPUT_CONTENT[1]:-}"

        if [[ "$INPUT_FILE" == *.sh ]] || [[ "$first_line" == "#!" || "$second_line" == "#!" ]]; then
            ok
        else
            ok "Not Found"
            echo "Unable to verify! Make sure that your file is either starts with a #! or has '.sh' extension."
            exit 1
        fi
    }

    has_any_prefix() {
        hasPrefix=0
        for line in ${INPUT_CONTENT[@]}; do
            if [[ "$line" == $PREFIX* ]]; then
                hasPrefix=1
                break
            fi
        done

        if [[ $hasPrefix -ne 1 ]]; then
            echo "Cannot found any annotations! This is required to split the files accordingly."
            exit 1
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

update_srcs() {
    # Build a list of current function files
    existing_files=()
    while IFS= read -r -d '' file; do
        existing_files+=("$file")
    done < <(find "$SPLITFILEDIR" -mindepth 1 -maxdepth 1 -type f -print0)

    # Track files that should exist after update
    updated_files=()

    # Populate func, since write_srcs is not called
    record=0
    while IFS= read -r line; do
        if [[ $line == "${PREFIX} sourceable.list" ]]; then
            record=1
            continue
        elif [[ $line == "${PREFIX} sourceable.list END" ]]; then
            record=0
            break
        fi

        [[ $record -eq 1 ]] && func_lists+=("$line")
    done < "$HEADFILE"

    # Iterate over func_lists (these are the target functions with path)
    for func in "${func_lists[@]}"; do

        # Purify path from symbolic prefix, if present
        func_path="${func#source }"
        func_path="${func_path#exec }"
        func_path="${func_path#eval }"

        updated_files+=("$func_path")

        # Gather new content from INPUT_CONTENT to reference from (New)
        func_name="$(basename "$func_path" .sh)" # Strip to only name
        new_content=()
        within_func=0
        for line in "${INPUT_CONTENT[@]}"; do
            for token in "${anyInputToken[@]}"; do
                if [[ "$line" == "${PREFIX}${token} $func_name" ]]; then
                    within_func=1
                    break
                fi
            done

            # Ending the function block
            if [[ "$within_func" -eq 1 ]] && [[ "$line" == "$PREFIX "* ]] && [[ ! " ${anyInputToken[@]} " =~ " ${line#$PREFIX} " ]]; then
                within_func=0
            fi

            [[ "$within_func" -eq 1 ]] && new_content+=("$line")
        done

        # Skip if function has no content
        [[ ${#new_content[@]} -eq 0 ]] && continue

        # Overwrite, or create new file on difference
        if [[ ! -f "$func_path" ]] || ! cmp -s <(printf "%s\n" "${old_content[@]}") <(printf "%s\n" "${new_content[@]}"); then
            printf "%s\n" "${new_content[@]}" > "$func_path"
            chmod +x "$func_path"
            echo "Updated: $func_path"
        fi


        # Convert new content to string 
        new_content_data=$(printf "%s\n" "${new_content[@]}")

        # Overwriting time 
        printf "%s\n" "${new_content[@]}" > "$func_path"
        
        echo "Updated: $func_path"
    done

    # Prompt before removing old files no longer present
    for f in "${existing_files[@]}"; do
        if [[ ! " ${updated_files[*]} " =~ " $f " ]]; then
            read -n1 -p "Obsolete file '$f' found. Remove? [y/N]: " ans
            echo
            case "${ans,,}" in   # convert to lowercase
                y)
                    rm -f "$f"
                    echo "Removed: $f"
                    ;;
                *)
                    echo "Skipped: $f"
                    ;;
            esac
        fi
    done
}

write_srcs() {
    for line in "${INPUT_CONTENT[@]}"; do
        if [[ "$line" == $PREFIX* ]] && [[ $(get_type_token $line) != "${IGNORE_SYMBOL}" ]]; then
            # Close previous function file if it exists
            [[ -n "$output_file" ]] && exec 3>&-

            # Make the previous file executable
            [[ ! -z "$output_file" ]] && chmod +x "$output_file"

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

verify_file

if [[ ! -d "$SPLITFILEDIR" ]]; then
    create_srcs
else 
    update_srcs
fi

# Initialize headfile with shebang
if [[ ! -f "$HEADFILE" ]]; then
    create_headfile
else
    update_headfile
fi

