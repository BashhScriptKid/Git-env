#------------------------------------------------------------------------------
# User Interface
#------------------------------------------------------------------------------

# Print startup header
print_header() {
    [[ ${PRINT_HEADER} -eq 0 ]] && return

    cat <<EOF
Entering Git shell. Press Ctrl+D or type 'exit' to quit.
Prefix commands with '>' to execute shell commands
EOF

    # Show LazyGit keybind if available
    if [[ -t 0 ]] && command -v lazygit >/dev/null 2>&1; then
        echo "Press Ctrl+G to launch LazyGit"
        echo
    fi
}

# Generate dynamic prompt
generate_prompt() {
    if check_git_repository; then
        # In Git repository
        local repo_name branch_info subdir root_indicator

        repo_name=$(basename "$(git rev-parse --show-toplevel)" 2>/dev/null || echo "unknown")
        branch_info=$(parse_git_branch)
        subdir=$(git rev-parse --show-prefix 2>/dev/null | sed 's:/$::')

        # Add root indicator if not in filesystem root
        local curr_dir parent_dir
        curr_dir=$(pwd -P)
        parent_dir=$(dirname "$curr_dir")
        [[ "$parent_dir" != "/" ]] && root_indicator=".../"

        echo -e "\e[34m[\e[1m${root_indicator}${repo_name}/${subdir}\e[32m${branch_info}\e[0m\e[34m]Git>\e[0m "
    else
        # Not in Git repository
        echo -e "[\e[93m\e[1mN/A\e[0m]Git> "
    fi
}

# Default action when empty command is entered
handle_empty_command() {
    # Could display status here, but currently does nothing
    # display_git_status
    :
}

