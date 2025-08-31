#------------------------------------------------------------------------------
# History Management
#------------------------------------------------------------------------------

# Initialize command history
setup_command_history() {
    export HISTCONTROL=ignoredups:ignorespace
    export HISTFILE_MAIN="$MAIN_HISTORY_FILE"
    export HISTSIZE=1000
    export HISTFILESIZE=2000

    # Create temporary history file for current session
    HISTFILE=$(mktemp /tmp/git-env_hist.XXXXXXXX)
    export HISTFILE

    # Disable history during setup
    set +o history

    # Set up arrow key history navigation (interactive mode only)
    if [[ -t 0 ]]; then
        bind '"\e[A": history-search-backward' 2>/dev/null
        bind '"\e[B": history-search-forward' 2>/dev/null
    fi

    # Load main history file
    if history -r "$HISTFILE_MAIN"; then
        log "Loaded history from $HISTFILE_MAIN"
    else
        log "Could not load history from $HISTFILE_MAIN"
    fi

    log "Session history will be saved to $HISTFILE"
}

# Save and merge command history
save_command_history() {
    log n "Saving command history..."

    if history -w; then
        log p "ok."
    else
        log p "failed."
        return 1
    fi

    log "Merging with main history file..."
    if cat "$HISTFILE" >> "$HISTFILE_MAIN"; then
        log p "ok."
    else
        log n p "failed."
        return 1
    fi

    # Clean up temporary file
    [[ -f "$HISTFILE" ]] && rm "$HISTFILE"
    log "Cleaned up session history file"
}

