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

Would you like to copy it for use with Git-env?
This will create a copy as .git-envrc without affecting your GitSh setup.

Note: Functionality may not be 100% compatible with GitSh.
EOF
        read -rp "Copy GitSh config? (y/n): " answer

        if [[ ${answer} =~ ^[Yy]$ ]]; then
            echo "Copying .gitshrc to .git-envrc..."
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

