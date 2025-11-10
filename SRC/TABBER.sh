#------------------------------------------------------------------------------
# Tab Completion System
#------------------------------------------------------------------------------

# Attempt to source completion files
try_source_completion() {
    local file="$1"
    log n "   Sourcing ${file}..."

    # shellcheck source=/dev/null
    if [[ -f "$file" ]] && source "$file" 2>/dev/null; then
        log p "ok."
        return 0
    else
        log p "failed."
        return 1
    fi
}

# Initialize Git tab completion
setup_git_completion() {
    [[ ${NO_SOURCING} -eq 1 ]] && return

    log "Attempting to source Git completion files:"

    # Try common completion file locations
    if ! try_source_completion "/usr/share/git/completion/git-completion.bash" &&
       ! try_source_completion "/etc/bash_completion.d/git"; then
        echo "Warning: Unable to find Git completion files"
    fi
    echo # Add spacer
}

# Advanced tab completion for Git-env
setup_custom_tab_completion() {
    [[ ! -t 0 ]] && return # Only for interactive terminals

    # Find common prefix among completions
    find_common_prefix() {
        local -a completions=("$@")
        local prefix="${completions[0]}"

        for ((i = 1; i < ${#completions[@]}; i++)); do
            local current="${completions[i]}"
            local temp_prefix=""

            # Find common characters from start
            for ((j = 0; j < ${#prefix} && j < ${#current}; j++)); do
                if [[ "${prefix:$j:1}" == "${current:$j:1}" ]]; then
                    temp_prefix+="${prefix:$j:1}"
                else
                    break
                fi
            done

            prefix="$temp_prefix"
            [[ -z "$prefix" ]] && break
        done

        echo "$prefix"
    }

    # Check if line contains remote reference that needs branch completion
    has_remote_branch_context() {
        local line="$1"

        # Skip openweb commands
        [[ "$line" =~ openweb ]] && return 1

        # Get remotes and check if line contains any
        local remotes
        remotes=$(git remote 2>/dev/null | tr '\n' '|')
        remotes=${remotes%|}  # Remove trailing |

        [[ -n "$remotes" && "$line" =~ [[:space:]](${remotes})[[:space:]] ]]
    }

    # Main completion function
    complete_git_env() {
        local line="${READLINE_LINE}"
        local point="${READLINE_POINT}"

        # Find word boundaries
        local word_start=$point
        while [[ $word_start -gt 0 && "${line:$((word_start-1)):1}" != " " ]]; do
            ((word_start--))
        done

        local current_word="${line:$word_start:$((point-word_start))}"
        local completions=("")

        # Handle different completion contexts
        if [[ "$current_word" == \>* ]]; then
            # Shell command completion (commands prefixed with >)
            local shell_cmd="${current_word#>}"
            mapfile -t completions < <(compgen -c "$shell_cmd" | sed 's/^/>/')

        elif [[ "$current_word" == "openweb" ]] || [[ "$line" =~ openweb[[:space:]]+$ ]]; then
            # Git remote completion for openweb command
            mapfile -t completions < <(git remote 2>/dev/null || echo "")

        else
            # Git command completion
           # Git commands - comprehensive list
            local git_commands="config help bugreport init clone add status diff commit notes restore reset rm mv branch checkout switch merge mergetool log stash tag worktree fetch pull push remote submodule show difftool range-diff shortlog describe apply cherry-pick rebase revert bisect blame grep am imap-send format-patch send-email request-pull svn fast-import clean gc fsck reflog filter-branch instaweb archive bundle daemon update-server-info cat-file check-ignore checkout-index commit-tree count-objects diff-index for-each-ref hash-object ls-files ls-tree merge-base read-tree rev-list rev-parse show-ref symbolic-ref update-index update-ref verify-pack write-tree"
            local script_commands="help exit lazygit openweb"

            mapfile -t completions < <(compgen -W "${git_commands} ${script_commands}" -- "${current_word}")

            # Context-specific completions
            if [[ "$line" =~ "help " ]]; then
                mapfile -t completions < <(compgen -W "${git_commands}}" -- "${current_word}")
            elif [[ "$line" =~ (add|rm|mv)[[:space:]] ]]; then
                # File completions for file-related commands
                local file_completions

                file_completions=$(compgen -f -- "$current_word")

                completions+=("${file_completions[@]}")
            elif [[ "$line" =~ (pull|push|fetch)[[:space:]] ]]; then
                # Remote completions
                local remote_completions

                remote_completions=$(git remote 2>/dev/null | tr '\n' ' ')

                mapfile -t completions < <(compgen -W "${remote_completions}" -- "${current_word}")
            # For git config
            elif [[ "${line}" = "config " ]]; then
                local config_completion="list get set unset rename-section remove-section edit"
                local name_completion

                name_completion="$(git config list --name)"

                mapfile -t completions < <(compgen -W "${config_completion} ${name_completion}" -- "${current_word}")
            elif [[ "$line" =~ "checkout " ]]; then
                # Branch completions for checkout
                local branches
                branches=$(git branch 2>/dev/null | sed 's/^[[:space:]]*//' | sed 's/.*\///' | sort -u)
                mapfile -t completions < <(compgen -W "$branches" -- "$current_word")
            fi

            ## Doesn't work within the else-if chain; keep this way for now
            # Append remotes with branch names
            local remotes=$(git remote 2>/dev/null | tr '\n' '|')
            remotes=${remotes%|}  # Remove trailing |
            if [[ -n "$remotes" && "$line" =~ [[:space:]](${remotes})[[:space:]] && ! "$line" =~ openweb ]]; then
                local branch_completion=$(git branch 2>/dev/null | sed 's/^[[:space:]]*//' | sed 's/.*\///' | sort -u | tr '\n' ' ')
                completions=$(compgen -W "${branch_completion}" -- "${current_word}")
            fi
        fi

        # Process completions
        if ((${#completions[@]} > 0)); then
            local completion_array=("${completions[@]}")
            local num_completions=${#completion_array[@]}

            if [[ $num_completions -eq 1 ]]; then
                # Single completion - insert it
                READLINE_LINE="${line:0:$word_start}${completion_array[0]}${line:$point}"
                READLINE_POINT=$((word_start + ${#completion_array[0]}))

            elif [[ $num_completions -gt 1 ]]; then
                # Multiple completions - find common prefix
                local common_prefix
                common_prefix=$(find_common_prefix "${completion_array[@]}")

                if [[ -n "$common_prefix" && ${#common_prefix} -gt ${#current_word} ]]; then
                    # Complete to common prefix
                    READLINE_LINE="${line:0:$word_start}${common_prefix}${line:$point}"
                    READLINE_POINT=$((word_start + ${#common_prefix}))
                fi

                # Display available completions
                display_completions "${completion_array[@]}"
            fi
        fi
    }

    # Display completions in columns
    display_completions() {
        local completions=("$@")
        local num_completions=${#completions[@]}
        local response="Y"

        if [[ $num_completions -gt 10 ]]; then
            echo "Display all $num_completions possibilities? (y or n)"
            read -r -n1 -s response
        fi

        [[ ! "$response" =~ ^[Yy]$ ]] && return 0

        echo
        echo "Available completions:"

        # Calculate display layout
        local cols
        local max_len=0

        cols=$(tput cols 2>/dev/null || echo 80)

        # Find longest completion
        for comp in "${completions[@]}"; do
            [[ ${#comp} -gt $max_len ]] && max_len=${#comp}
        done

        local col_width=$((max_len + 2))
        local num_cols=$((cols / col_width))
        [[ $num_cols -lt 1 ]] && num_cols=1

        # Print in columns
        local count=0
        for comp in "${completions[@]}"; do
            printf "%-${col_width}s" "$comp"
            ((count++))
            if [[ $((count % num_cols)) -eq 0 ]]; then
                echo
            fi
        done
        [[ $((count % num_cols)) -ne 0 ]] && echo
    }

    # Bind Tab key to completion function
    bind -x '"\t": complete_git_env' >/dev/null 2>&1 # It complains, but works
    log "Custom tab completion enabled"
}

