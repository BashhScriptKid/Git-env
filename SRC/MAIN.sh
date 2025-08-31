#------------------------------------------------------------------------------
# Main Program Loop
#------------------------------------------------------------------------------

# Main interactive loop
main_loop() {
    local cmd exit_code

    # Clear initial history anomaly
    if [[ ${INIT_CLEAR} -eq 0 ]]; then
        history -c
        INIT_CLEAR=1
        log "Cleared initial history entry"
    fi

    while true; do
        # Update repository status
        check_git_repository >/dev/null

        trap 'handle_interrupt' SIGINT

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
                echo "Exiting Git-env..."
                break
            fi
        fi
    done
}

#------------------------------------------------------------------------------
# Program Entry Point
#------------------------------------------------------------------------------

main() {
    # Initial safety checks
    disable_history_expansion

    # Process command line arguments
    process_arguments "$@"

    # Save argument data in case of update / SIGINT
    ARG=("$@")


    # Core initialization
    check_git_installation
    setup_working_directory

    # Check for non-interactive mode
    if [[ $- != *i* ]]; then
        echo -e "\e[93m\e[1mWarning: Running in non-interactive mode. Some features may not work.\e[0m"
    fi

    # Setup components
    setup_git_completion
    setup_custom_tab_completion
    setup_command_history
    setup_rc_file
    initialise_keybinds >/dev/null 2>&1 # It complains, but works

    # Setup signal handlers
    trap 'handle_termination' SIGTERM
    trap 'handle_interrupt' SIGINT
    trap 'cleanup_and_exit' EXIT

    # Display startup information
    print_header

    # Enter main interactive loop
    main_loop
}

