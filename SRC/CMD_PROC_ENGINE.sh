#------------------------------------------------------------------------------
# Command Processing Engine
#------------------------------------------------------------------------------

# Execute individual command
execute_command() {
    local cmd="$1"
    local git_path="${2:-$GIT_PATH}"
    local last_exit_code=0

    if [[ -z "${cmd}" ]]; then
        return 0
    fi

    case "$cmd" in
        "exit")
            log "Exit command received"
            return 24  # Special exit code
            ;;

        "git"*)
            echo "You're already in a Git shell!"
            eval "${git_path}" "${cmd#git }"
            last_exit_code=$?
            [[ $last_exit_code -eq 0 ]] && history -s "${cmd}"
            ;;

        "lazygit")
            if command -v lazygit >/dev/null 2>&1; then
                echo "Starting LazyGit..."
                lazygit
                last_exit_code=$?
            else
                echo -e "\e[93m\e[1mError: LazyGit is not installed\e[0m"
                last_exit_code=1
            fi
            ;;

        "openweb"*)
            open_repository_web "${cmd#openweb }"
            last_exit_code=$?
            ;;

        "help")
            git help
            echo -e "\n\e[1m\e[34mAdditional Git-env commands:\e[0m"
            cat <<'EOF'
  openweb     Open repository in web browser
  lazygit     Launch LazyGit TUI (requires installation)
  >command    Execute shell command (prefix with >)
EOF
            last_exit_code=0
            ;;

        \>*)
            # Shell command execution (prefixed with >)
            local shell_cmd="${cmd#>}"
            shell_cmd="$(echo "${shell_cmd}" | xargs)" # Trim whitespace

            if [[ -n "${shell_cmd}" ]]; then
                log "Executing shell command: ${shell_cmd}"
                eval "${shell_cmd}"
                last_exit_code=$?
                [[ $last_exit_code -eq 0 ]] && history -s "${cmd}"
            fi
            ;;

        "")
            # Empty command - do nothing
            last_exit_code=0
            ;;

        *)
            # Regular Git command
            log "Executing Git command: ${git_path} ${cmd}"
            eval "${git_path}" "${cmd}"
            last_exit_code=$?
            [[ $last_exit_code -eq 0 ]] && history -s "${cmd}"
            ;;
    esac

    return $last_exit_code
}

# Process command line with operator support (&&, ||, ;)
process_command_line() {
    local input="$1"
    local git_path="${2:-$GIT_PATH}"

    # Trim whitespace
    input="$(echo "$input" | xargs)"
    [[ -z "$input" ]] && return 0

    # Split on operators while preserving quoted strings
    local IFS=$'\n'
    local commands

    mapfile -t commands < <(echo "$input" | sed 's/\(&&\|;;\||\|;\)/\n&\n/g' | sed '/^$/d')

    local last_exit_code=0
    local should_execute=true

    while [[ ${#commands[@]} -gt 0 ]]; do
        local cmd="${commands[0]}"
    commands=("${commands[@]:1}")  # drop first element

        case "$cmd" in
            "&&")
                # AND operator: execute next only if last succeeded
                should_execute=$([[ $last_exit_code -eq 0 ]] && echo true || echo false)
                log "AND operator: should_execute=${should_execute}"
                ;;
            "||")
                # OR operator: execute next only if last failed
                should_execute=$([[ $last_exit_code -ne 0 ]] && echo true || echo false)
                log "OR operator: should_execute=${should_execute}"
                ;;
            ";")
                # Sequential operator: always execute next
                should_execute=true
                log "Sequential operator: should_execute=${should_execute}"
                ;;
            *)
                # Command execution
                if [[ "${should_execute}" == true ]]; then
                    cmd="$(echo "${cmd}" | xargs)" # Trim whitespace
                    execute_command "${cmd}" "${git_path}"
                    last_exit_code=$?
                else
                    log "Skipping command: ${cmd} (condition not met)"
                fi
                ;;
        esac
    done


    return $last_exit_code
}

