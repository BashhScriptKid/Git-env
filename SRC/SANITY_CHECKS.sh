#------------------------------------------------------------------------------
# Initialization & Safety Checks
#------------------------------------------------------------------------------

# Prevent script from being sourced
(return 0 2>/dev/null) && {
    echo "PLEASE Don't source this script — run it directly with ./git-shell.sh"
    return 1
}


# Verify Git installation
check_git_installation() {
    if ! command -v git >/dev/null 2>&1; then
        echo "Error: Git is not installed or not in PATH."
        exit 1
    fi
}

# Disable history expansion to prevent issues with ! characters
disable_history_expansion() {
    set +H
}

