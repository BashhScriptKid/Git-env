#------------------------------------------------------------------------------
# Signal Handlers
#------------------------------------------------------------------------------

# Handle Ctrl+C (SIGINT)
handle_interrupt() {
    echo -n
    exec "$0" --no-header "${ARG[@]}"
}

# Handle termination signals
handle_termination() {
    save_command_history
    echo
    echo "Git-env terminated. Goodbye!"
    exit 130
}

# Cleanup on normal exit
cleanup_and_exit() {
    set +o history
    save_command_history
    echo
    echo "Goodbye!"
    exit 0
}

