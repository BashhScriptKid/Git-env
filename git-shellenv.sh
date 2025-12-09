#!/bin/bash -i

##==============================================================================
## Igitari — A kindly powerful Git companion
## Make Git approachable without sacrificing its power
##==============================================================================
## Version: 3.0
## Author: BashhScriptKid <contact@bashh.slmail.me>
## Copyright (C) 2025 BashhScriptKid
## SPDX-License-Identifier: AGPL-3.0-or-later
##
##   This program is free software: you can redistribute it and/or modify
##   it under the terms of the GNU Affero General Public License as published
##   by the Free Software Foundation, either version 3 of the License, or
##   (at your option) any later version.
##
##   This program is distributed in the hope that it will be useful,
##   but WITHOUT ANY WARRANTY; without even the implied warranty of
##   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##   GNU Affero General Public License for more details.
##
##   You should have received a copy of the GNU Affero General Public License
##   along with this program.  If not, see <https://www.gnu.org/licenses/>.
##
##==============================================================================
##
## "#--" is for decompilation purposes; please do not remove those lines on master branch

#--|CONSTANTS
#------------------------------------------------------------------------------
# Configuration Constants
#------------------------------------------------------------------------------
readonly IGITARI_VERSION="1.4-l"

readonly GITSH_RC_FILE="${HOME}/.gitshrc"

readonly DEFAULT_GIT_PATH="/usr/bin/git"

readonly LOCALPATH="${HOME}/.local/share/igitari/"
readonly RC_FILE="${LOCALPATH}.igitari-rc"
readonly MAIN_HISTORY_FILE="${LOCALPATH}.igitari_hist"

readonly REMOTE_LINK="https://github.com/BashhScriptKid/Igitari"

#--|CONFIG_VARS
#------------------------------------------------------------------------------
# Global Variables
#------------------------------------------------------------------------------
# Configuration flags
DO_LOGGING=0
NO_SOURCING=1
INIT_CLEAR=0
PRINT_HEADER=1
NOT_GitDir=0
CHECK_UPDATES=1
NO_MARKERS=0
# shellcheck disable=SC2034
readonly PROFESSIONAL_PERSONALITY=1

RUNTIME_VERSION="$(cat "${LOCALPATH}"ref.sha)(${IGITARI_VERSION})"

# Runtime variables
TARGET_PATH=""
GIT_PATH=${DEFAULT_GIT_PATH}
HISTFILE=""
LAST_DIR=""
ARG=""
REPO_IS_DIRTY=0
REPO_IS_DIRTY_AND_STAGED=0
REPO_STASH_DIRTY=0

#--|SANITY_CHECKS
#------------------------------------------------------------------------------
# Initialization & Safety Checks
#------------------------------------------------------------------------------

# Verify Git installation
check_git_installation() {
    if ! command -v git >/dev/null 2>&1; then
        echo "Error: Git is not installed or not in PATH."
        exit 1
    fi
}

check_localpath() {
    if [ ! -d "${LOCALPATH}" ]; then
        echo "Error: Local path ${LOCALPATH} does not exist. Creating..."
        mkdir -p "${LOCALPATH}"
    fi
}

get_commithash_ref() {
    latest_remote_sha="$(git ls-remote ${REMOTE_LINK}.git HEAD | awk '{print $1}')"
    echo "$latest_remote_sha" >>"${LOCALPATH}ref.sha"
}

# Disable history expansion to prevent issues with ! characters
disable_history_expansion() {
    set +H
}

# Prevent script from being sourced
# shellcheck disable=SC2154
(return 0 2>/dev/null) && test "$inHead" -ne 1 && {
    echo "PLEASE Don't source this script — run it directly with ./git-shell.sh"
    return 1
}

#--|LOGGER
#------------------------------------------------------------------------------
# Logging System
#------------------------------------------------------------------------------

# Enhanced logging function with formatting options
# Usage: log [flags] "message"
# Flags: n (no newline), p (no prefix)
log() {
    local prefix
    local skip_newline=false
    local skip_prefix=false

    prefix="Igitari_debug: [$(date +%T)] "

    # Parse flags
    while [[ $# -gt 1 ]]; do
        case "$1" in
        n) skip_newline=true ;;
        p) skip_prefix=true ;;
        *) : ;; # Ignore unknown flags
        esac
        shift
    done

    # Only log if verbose mode is enabled
    [[ ${DO_LOGGING} -ne 1 ]] && return

    # Format output
    [[ ${skip_prefix} == true ]] && prefix=""

    if [[ ${skip_newline} == true ]]; then
        echo -n "${prefix}${1}"
    else
        echo "${prefix}${1}"
    fi
}

#--|DATA_SHOWOFF
# Display help information
show_help() {
    cat <<EOF
Igitari version ${RUNTIME_VERSION}

The lightweight and portable Git shell environment.
Supports DOS/GNU/Unix argument formats.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --help, -h, /?          Show this help and exit
    --version, -v           Show version information and exit
    --path, -p [DIR]        Start shell in specified directory
    --verbose, -V           Enable debug logging
    --skip-sourcing         Skip sourcing tab completion files
    --no-header             Suppress startup header (internal use)

EXAMPLES:
    $0 --path /home/user/project    # Start in specific directory
    $0 --verbose                    # Enable debug output
    $0 /?                           # Show help
EOF
}

# Display version and about information
show_version() {
    cat <<EOF
Igitari version ${RUNTIME_VERSION}

About:
    A kindly powerful Git companion,
    born from the simple desire to type 'git' less often.

    Make Git approachable without sacrificing its power —
    because you shouldn't fight your tools to do great work.

    Lightweight, portable, and almost dependency-free.
    The Git shell that watches your back for silly mistakes.

    Repository: https://github.com/BashhScriptKid/igitari
    License: AGPL-3.0-or-later

    Crafted in Bash by BashhScriptKid
EOF
    #'
}

#--|ARG_PROCESSOR
#------------------------------------------------------------------------------
# Argument Processing
#------------------------------------------------------------------------------

# Process command line arguments
process_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
        "--help" | "-h" | "/?" | "/HELP" | "/H" | "/help" | "/h")
            show_help
            exit 0
            ;;
        "version" | "--version" | "-v" | "/VERSION" | "/version" | "/v")
            show_version
            exit 0
            ;;
        "--path" | "-p" | "/PATH" | "/P" | "/path" | "/p")
            shift
            if [[ -z "$1" ]]; then
                echo "Error: --path requires a directory argument"
                exit 1
            elif [[ -f "$1" ]]; then
                echo "Error: Path must be a directory, not a file"
                exit 1
            else
                TARGET_PATH="$1"
            fi
            ;;
        "verbose" | "-V" | "--verbose" | "/VERBOSE" | "/verbose" | "/V")
            DO_LOGGING=1
            echo "Verbose logging enabled"
            ;;
        "skip-sourcing" | "--skip-sourcing" | "/SKIP-SOURCING")
            echo "Tab completion sourcing disabled"
            NO_SOURCING=1
            ;;
        "--no-header")
            log "Restarting shell without header"
            PRINT_HEADER=0
            ;;
        *)
            echo "Warning: Unknown argument '$1' ignored"
            ;;
        esac
        shift
    done
}

#--|DIR_CHANGE
#------------------------------------------------------------------------------
# Directory Management
#------------------------------------------------------------------------------

# Change to user-specified directory if provided
setup_working_directory() {
    if [[ -n "${TARGET_PATH}" ]]; then
        LAST_DIR=$(pwd)
        if ! cd "${TARGET_PATH}"; then
            echo "Error: Cannot change to directory: ${TARGET_PATH}"
            exit 1
        fi
        # Set trap to restore original directory on exit
        trap 'cd "$LAST_DIR"' EXIT SIGTERM
        log "Changed working directory to: ${TARGET_PATH}"
    fi
}

#--|TABBER
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

# Advanced tab completion for Igitari
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
        remotes=${remotes%|} # Remove trailing |

        [[ -n "$remotes" && "$line" =~ [[:space:]](${remotes})[[:space:]] ]]
    }

    # Main completion function
    complete_git_env() {
        local line="${READLINE_LINE}"
        local point="${READLINE_POINT}"

        # Find word boundaries
        local word_start=$point
        while [[ $word_start -gt 0 && "${line:$((word_start - 1)):1}" != " " ]]; do
            ((word_start--))
        done

        local current_word="${line:$word_start:$((point - word_start))}"
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
            else
                # File completions for anything else
                local file_completions

                file_completions=$(compgen -f -- "$current_word")
            fi

            ## Doesn't work within the else-if chain; keep this way for now
            # Append remotes with branch names
            local remotes=$(git remote 2>/dev/null | tr '\n' '|')
            remotes=${remotes%|} # Remove trailing |
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

#--|GIT_FUNC
#------------------------------------------------------------------------------
# Git Repository Functions
#------------------------------------------------------------------------------

# Parse current Git branch
parse_git_branch() {
    local branch_list
    branch_list=$(git branch 2>/dev/null) || return 1

    if [[ -n "${branch_list}" ]]; then
        echo "${branch_list}" | sed -n 's/^\* //p'
    else
        return 1
    fi
}

# Evaluate cleanliness
dirty_check() {
    if ! git diff --quiet >/dev/null; then
        REPO_IS_DIRTY=1
    else
        REPO_IS_DIRTY=0
    fi

    if ! git diff --staged --quiet >/dev/null; then
        REPO_IS_DIRTY_AND_STAGED=1
    else
        REPO_IS_DIRTY_AND_STAGED=0
    fi

    if git rev-parse --verify refs/stash >/dev/null; then
        REPO_STASH_DIRTY=1
    else
        REPO_STASH_DIRTY=0
    fi
}

# Display Git repository status
display_git_status() {
    local branch
    branch=$(parse_git_branch) || branch='None (Not in git repository.)'

    echo "On branch ${branch}"
    git status 2>/dev/null || echo "Status undefined."
}

# Check if current directory is in a Git repository
check_git_repository() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        if [[ "${NOT_GitDir}" != "1" ]]; then
            echo -e "\e[93m\e[1mWarning: Not in a Git repository."
            echo -e "Type 'init' to create a new repository in this directory.\e[0m"
            NOT_GitDir=1
        fi
        return 1
    else
        NOT_GitDir=0
        return 0
    fi
}

#--|EXTRAS
#------------------------------------------------------------------------------
# Custom features
#------------------------------------------------------------------------------

# Open repository in web browser
# Usage: openweb [remote] [page]
# Pages: issues, pr, pull-request, wiki, settings
open_repository_web() {
    local remote="$1"
    local page="$2"

    # Validate input
    if [[ -z "$remote" ]]; then
        echo "SYNTAX: openweb [remote] [issues|pr|pull-request|wiki|settings]"
        return 1
    fi

    # Get remote URL
    local remote_url
    remote_url=$(git remote get-url "$remote" 2>/dev/null)

    if [[ -z "$remote_url" ]]; then
        echo -e "\e[91m\e[1mError: Remote '$remote' not found.\e[0m"
        echo "SYNTAX: openweb [remote] [issues|pr|pull-request|wiki|settings]"
        return 1
    fi

    # Clean URL and append page path
    remote_url="${remote_url%.git}"
    log "Base URL: ${remote_url}"

    case "$page" in
    "issues") remote_url="${remote_url}/issues" ;;
    "pr" | "pull-request") remote_url="${remote_url}/pulls" ;;
    "wiki") remote_url="${remote_url}/wiki" ;;
    "settings") remote_url="${remote_url}/settings" ;;
    "") : ;; # No page specified
    *) echo "Error: Unknown page '$page'" && return 1 ;;
    esac

    # Open URL in default browser (cross-platform)
    if command -v xdg-open >/dev/null; then
        log "Opening with xdg-open (Linux)"
        xdg-open "$remote_url" >/dev/null 2>&1 &
    elif command -v open >/dev/null; then
        log "Opening with open (macOS)"
        open "$remote_url"
    elif command -v cmd.exe >/dev/null; then
        log "Opening with cmd (Windows)"
        cmd.exe /C start "" "$remote_url"
    else
        echo -e "\e[91m\e[1mError: Unable to detect browser opener for this OS\e[0m"
        return 1
    fi

    echo "Opened: $remote_url"
    echo "Check your browser, or Ctrl+click this link to open manually."
}

# Initialise keybinds
# This is for non-core features that users can simply add.
# Interactive mode only!
initialise_keybinds() {
    # Don't initialise on non-interactive mode
    if [[ $- != *i* ]]; then
        return
    fi

    #-----------------#
    #     Macros      #
    #-----------------#

    # This is for more advanced operations that require more than executing single-line commands.

    f_lazygit() {
        if command -v lazygit >/dev/null 2>&1; then
            lazygit
        fi
    }

    ### Keybind setup

    # Refer to https://www.gnu.org/software/bash/manual/html_node/Bindable-Readline-Commands.html
    # OR https://www.geeksforgeeks.org/linux-unix/bind-command-in-linux-with-examples/ for usage

    # CTRL + G
    bind -x '"\C-g":f_lazygit'

}

#--|CMD_PROC_ENGINE
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
        return 24 # Special exit code
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
        echo -e "\n\e[1m\e[34mAdditional Igitari commands:\e[0m"
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

    mapfile -t commands < <(echo "$input" | awk '{
        gsub(/&&|\|\||;;|;/, "\n&\n")
        print
    }' | sed '/^$/d')

    local last_exit_code=0
    local should_execute=true

    while [[ ${#commands[@]} -gt 0 ]]; do
        local cmd="${commands[0]}"
        commands=("${commands[@]:1}") # drop first element

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

#--|HIST_MGMT
#------------------------------------------------------------------------------
# History Management
#------------------------------------------------------------------------------

# Initialize command history
setup_command_history() {
    export HISTCONTROL=ignoredups:ignorespace
    export HISTFILE="$MAIN_HISTORY_FILE"
    export HISTSIZE=1000
    export HISTFILESIZE=2000

    if [[ ! -f "$HISTFILE" ]]; then
        echo "Creating main history file..."
        touch "$HISTFILE"
        chmod 600 "$HISTFILE"
    fi

    # Disable history during setup
    set +o history

    # Set up arrow key history navigation (interactive mode only)
    if [[ -t 0 ]]; then
        bind '"\e[A": history-search-backward' 2>/dev/null
        bind '"\e[B": history-search-forward' 2>/dev/null
    fi

    # Load main history file
    if history -r; then
        log "Loaded history from $HISTFILE"
    else
        log "Could not load history from $HISTFILE"
    fi

    log "Session history will be saved to $HISTFILE"
}

#--|RC_SETUP
#------------------------------------------------------------------------------
# RC File Management
#------------------------------------------------------------------------------

# Handle RC file initialization and GitSh compatibility
setup_rc_file() {
    # shellcheck source=/dev/null
    if [[ -f "$RC_FILE" ]]; then
        if [[ ${NO_SOURCING} -eq 0 ]]; then
            log n "Sourcing $RC_FILE..."
            if source "$RC_FILE"; then
                log p "ok."
            else
                log p "failed."
                echo "Warning: Error sourcing $RC_FILE. Continuing anyway."
            fi
        fi
    elif [[ -f "$GITSH_RC_FILE" && ${PRINT_HEADER} -eq 1 ]]; then
        # Offer to migrate from GitSh
        cat <<EOF
Found GitSh configuration file!

Would you like to copy it for use with Igitari?
This will create a copy as .igitari-rc without affecting your GitSh setup.

Note: Functionality may not be 100% compatible with GitSh.
EOF
        read -rp "Copy GitSh config? (y/n): " answer

        if [[ ${answer} =~ ^[Yy]$ ]]; then
            echo "Copying .gitshrc to .igitari-rc..."
            if cp "$GITSH_RC_FILE" "$RC_FILE"; then
                echo "Configuration copied successfully!"
                NO_SOURCING=0
                if source "$RC_FILE"; then
                    echo "Configuration loaded. This will be your default RC file."
                fi
            else
                echo "Error: Failed to copy configuration file."
            fi
        fi
    fi
}

#--|SIGHANDLERS
#------------------------------------------------------------------------------
# Signal Handlers
#------------------------------------------------------------------------------

# Handle Ctrl+C (SIGINT)
handle_interrupt() {
    # Ignore further SIGINT until we finish
    trap : SIGINT
    # Ensure terminal echo is on
    stty echo
    echo -n
    exec "$0" --no-header "${ARG[@]}"
}

# Handle termination signals
handle_termination() {
    history -w && log "Successfully saved command history."
    echo
    echo "Igitari terminated. Goodbye!"
    exit 130
}

# Cleanup on normal exit
cleanup_and_exit() {
    set +o history
    history -w && log "Successfully saved command history."
    echo
    echo "Goodbye!"
    exit 0
}

#--|INTERFACES
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
        local top subdir repo_name branch_info root_indicator dirty_markers

        # Resolve repository root and prefix safely
        top=$(git rev-parse --show-toplevel 2>/dev/null)
        subdir=$(git rev-parse --show-prefix 2>/dev/null)
        repo_name=${top##*/}

        # Add markers per dirty flag
        dirty_markers="" # Reset first
        if [[ ${NO_MARKERS} -ne 1 ]]; then
            [[ ${REPO_IS_DIRTY} -eq 1 ]] && dirty_markers+="\e[91m*\e[0m"
            [[ ${REPO_IS_DIRTY_AND_STAGED} -eq 1 ]] && dirty_markers+="\e[93m^\e[0m"
            [[ ${REPO_STASH_DIRTY} -eq 1 ]] && dirty_markers+="\e[94m_\e[0m"
        fi

        # Normalize subdir (remove trailing slash)
        subdir=${subdir%/}

        # Compact root indicator
        [[ "$(dirname "$PWD")" != "/" ]] && root_indicator=".../"

        branch_info=$(parse_git_branch)

        # Final prompt
        echo -e "\e[34m[\e[1m${root_indicator}${repo_name}/${subdir}\e[32m (${branch_info}${dirty_markers})\e[0m\e[34m]Git>\e[0m "
    else
        log "Repository no longer detected! Commands will stop working."
        echo -e "[\e[93m\e[1mN/A\e[0m]Git> "
    fi
}

# Default action when empty command is entered
handle_empty_command() {
    # Could display status here (per GitSh default), but currently does nothing
    # display_git_status
    :
}

#--|GIST_UPDATER
#------------------------------------------------------------------------------
# Updater (GitHub Gist)
#------------------------------------------------------------------------------

Updater() {
    if [[ ${CHECK_UPDATES} -ne 1 ]]; then
        log "Updater skipped (CHECK_UPDATES != 1)"
        return
    fi

    local UPDATER_URL='https://raw.githubusercontent.com/BashhScriptKid/Igitari/refs/heads/master/'
    local SCRIPT_URL="${UPDATER_URL}git-shellenv.sh"

    local latest_remote_sha
    local local_sha
    local version
    local status

    connection_checker() {
        log "Checking prerequisites..."

        if ! command -v curl >/dev/null 2>&1; then
            echo "Updater: curl not installed."
            log "curl not installed, updater cannot continue"
            return 1
        fi

        log "Testing connectivity to $UPDATER_URL"
        if ! curl -fsSL --max-time 5 --head "$UPDATER_URL" >/dev/null; then
            echo "Updater: remote unreachable."
            log "remote unreachable (timeout or no response)"
            return 254
        fi
        log "Connection OK"
    }

    compare_commithash() {
        log "Fetching commit differences from $UPDATER_URL"

        if [[ ! -f "${LOCALPATH}/ref.sha" ]]; then
            echo "Oh wow you broke the updater system, congrats. Go update it manually; bailing out."
            exit 1
        fi

        latest_remote_sha="$(git ls-remote ${REMOTE_LINK}.git HEAD | awk '{print $1}')"

        local_sha="$(cat "${LOCALPATH}ref.sha")"

        # Actually compare
        if [[ "$latest_remote_sha" == "$local_sha" ]]; then
            echo "Updater: local and remote versions are the same."
            log "local and remote versions are the same"
            return 0
        else
            echo "Updater: local and remote versions differ."
            echo "Local: $local_sha"
            echo "Remote: $latest_remote_sha"
            log "local and remote versions differ (${latest_remote_sha} != ${local_sha})"
            return 1
        fi

    }

    # shellcheck disable=SC2120
    replacer() {
        local TEMP_FILE

        broken_version_check() {
            if bash -n "$TEMP_FILE"; then
                echo -ne "\e[1m\e[93m"
                echo "This version is broken. Either you're using outdated Bash version or I made a mistake on writing. Try again later?"
                echo -ne "\e[0m"

                rm -f "$TEMP_FILE"
                return 1
            fi
        }

        TEMP_FILE=$(mktemp /tmp/update_gitsh-XXXX.sh) || {
            echo "Updater: failed to create temp file."
            log "mktemp failed, cannot continue update"
            return 1
        }

        SCRIPT_PATH="$(realpath "$0")"
        log "Script path resolved to $SCRIPT_PATH"
        log "Temp file created: $TEMP_FILE"

        echo "Updater: downloading latest script from:"
        echo "  $SCRIPT_URL"
        echo

        # Show progress, fail if error
        if curl -fL "$SCRIPT_URL" -o "$TEMP_FILE"; then
            log "Download complete ($TEMP_FILE)"

            broken_version_check || return 1
            log "Functionality/syntax test returned 0"

            (chmod +x "$TEMP_FILE" && bash -n "$TEMP_FILE") || (echo "Script check failed (see above)." && return 1)

            if [[ ! -s "$TEMP_FILE" ]]; then
                echo "Updater: downloaded file is empty, aborting."
                log "Downloaded file empty, aborting update"
                rm -f "$TEMP_FILE"
                return 1
            fi

            log "Overwriting script with new version"
            cat "$TEMP_FILE" >"$SCRIPT_PATH" && rm -f "$TEMP_FILE"

            echo
            echo "Updater: update complete. Restarting..."
            log "Exec restart: $SCRIPT_PATH $*"
            exec "$SCRIPT_PATH" "${ARG[@]}"
        else
            echo "Updater: failed to download new version."
            log "curl download failed"
            rm -f "$TEMP_FILE"
            return 1
        fi
    }

    commit_fetcher() {
        remote_json="$(curl -s "https://api.github.com/repos/BashhScriptKid/Igitari/compare/$local_sha...$latest_remote_sha")"

        echo "$remote_json" |
            awk '
            /"message":/ {
                sub(/.*"message": "/, "");
                sub(/",?$/, "");
                msg=$0;
            }
            /"name":/ {
                sub(/.*"name": "/, "");
                sub(/",?$/, "");
                print "* " msg " — " $0;
            }
        '
    }

    main_updater() {
        local response

        echo
        echo "New update is available!"
        echo
        echo "${RUNTIME_VERSION} -> ${latest_remote_sha}"
        echo
        echo "Changelogs:"
        commit_fetcher | sed 's/^/  /' # Indent changelogs
        echo

        log "Prompting user for update (current=$RUNTIME_VERSION, new=$latest_remote_sha)"
        read -rp "Would you like to update now? (Y/N) " -n1 response
        echo
        if [[ ${response} =~ ^[Yy]$ ]]; then
            log "User accepted update"
            replacer
        else
            log "User declined update"
        fi
    }

    main_checker() {
        log "Running update check..."
        connection_checker && compare_commithash

        # Pipe compare_commithash return code
        local status=$?
        if [[ $status -eq 1 ]]; then
            log "Update available"
            return 255
        elif [[ $status -eq 0 ]]; then
            log "No update available"
        else
            log "Function returned unexpected status code."
        fi
    }

    # Run synchronously for now so we can trust exit code
    status=0
    main_checker || status=$?

    if [[ $status -eq 255 ]]; then
        main_updater
    fi
}

do_update() {
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

    if [[ -n "$GIT_ROOT" && "$SCRIPT_DIR" == "$GIT_ROOT" ]]; then
        # Running from the repo root; skip auto-update
        log "Updater skipped: running from Igitari repo itself."
    else
        # Optionally also check remote URL
        REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
        if [[ "$REMOTE_URL" =~ github\.com[:/]+BashhScriptKid/Igitari ]]; then
            Updater &
        fi
    fi
}

#--|MAIN
#------------------------------------------------------------------------------
# Main Program Loop
#------------------------------------------------------------------------------

# Main interactive loop
main_loop() {
    local cmd exit_code

    while true; do
        # Update repository status
        check_git_repository >/dev/null
        dirty_check

        trap handle_interrupt SIGINT

        # Display prompt and read command
        if ! read -rep "$(generate_prompt)" cmd; then
            break # EOF (Ctrl+D) pressed
        fi

        # Process command
        if [[ -z "$cmd" ]]; then
            handle_empty_command
        else
            process_command_line "$cmd"
            exit_code=$?
            if [[ $exit_code -eq 24 ]]; then
                echo "Exiting Igitari..."
                break
            fi
        fi
    done
}
#------------------------------------------------------------------------------
# Program Entry Point
#------------------------------------------------------------------------------

main() {
    # Source RC file here since this allows for maximum function overloading
    setup_rc_file

    # Initial safety checks
    disable_history_expansion

    # Process command line arguments
    process_arguments "$@"

    # Save argument data in case of update / SIGINT
    ARG=("$@")

    # Core initialization
    check_git_installation
    check_localpath
    if [[ ! -f "${LOCALPATH}ref.sha" ]]; then
        log "Reference update commit hash not found, fetching latest (this may break if the script is run long after the file deletion)."
        get_commithash_ref
    fi

    setup_working_directory

    # Check for non-interactive mode
    if [[ $- != *i* ]]; then
        echo -e "\e[93m\e[1mWarning: Running in non-interactive mode. Some features may not work.\e[0m"
    fi

    # Setup components
    setup_git_completion
    setup_custom_tab_completion

    # Clear initial history anomaly
    if [[ ${INIT_CLEAR} -eq 0 ]]; then
        history -c
        INIT_CLEAR=1
        log "Cleared initial history entry"
    fi
    setup_command_history
    initialise_keybinds >/dev/null 2>&1 # It complains, but works

    # Setup signal handlers
    trap 'handle_termination' SIGTERM
    trap 'handle_interrupt' SIGINT
    trap 'cleanup_and_exit' EXIT

    # Display startup information
    print_header

    do_update

    # Enter main interactive loop
    main_loop
}

#--|m
#------------------------------------------------------------------------------
# Execute main function with all arguments
#------------------------------------------------------------------------------
main "$@"

#--|END
