#------------------------------------------------------------------------------
# Argument Processing
#------------------------------------------------------------------------------

# Process command line arguments
process_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            "--help"|"-h"|"/?"|"/HELP"|"/H"|"/help"|"/h")
                show_help
                exit 0
                ;;
            "version"|"--version"|"-v"|"/VERSION"|"/version"|"/v")
                show_version
                exit 0
                ;;
            "--path"|"-p"|"/PATH"|"/P"|"/path"|"/p")
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
            "verbose"|"-V"|"--verbose"|"/VERBOSE"|"/verbose"|"/V")
                DO_LOGGING=1
                echo "Verbose logging enabled"
                ;;
            "skip-sourcing"|"--skip-sourcing"|"/SKIP-SOURCING")
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

