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
        "issues")            remote_url="${remote_url}/issues" ;;
        "pr"|"pull-request") remote_url="${remote_url}/pulls" ;;
        "wiki")              remote_url="${remote_url}/wiki" ;;
        "settings")          remote_url="${remote_url}/settings" ;;
        "")             : ;; # No page specified
        *)              echo "Error: Unknown page '$page'" && return 1 ;;
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
initialise_keybinds()
{
    # Don't initialise on non-interactive mode
    if [[ $- != *i* ]]; then
        return
    fi

    #-----------------#
    #     Macros      #
    #-----------------#

    # This is for more advanced operations that require more than executing single-line commands.

    f_lazygit()
    {
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

