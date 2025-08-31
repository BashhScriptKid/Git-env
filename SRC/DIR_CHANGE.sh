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

