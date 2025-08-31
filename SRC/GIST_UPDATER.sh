#------------------------------------------------------------------------------
# Updater (GitHub Gist)
#------------------------------------------------------------------------------

Updater()
{
    if [[ ${CHECK_UPDATES} -ne 1 ]]; then
        log "Updater skipped (CHECK_UPDATES != 1)"
        return
    fi

    local UPDATER_URL='https://gist.githubusercontent.com/BashhScriptKid/ce5c1fdbd275430d1c5f444c9abdd0db/raw/'
    local SCRIPT_URL="${UPDATER_URL}git-shellenv.sh"
    local CHANGELOG_URL="${UPDATER_URL}le-changelog.txt"

    local changelog_output
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

    fetch() {
        log "Fetching changelog from $CHANGELOG_URL"
        changelog_output=$(curl -s "${CHANGELOG_URL}")
        version=$(head -n1 <<< "$changelog_output")
        log "Fetched changelog, detected version: ${version:-unknown}"
    }

    # shellcheck disable=SC2120
    replacer() {
        local TEMP_FILE

        sanity_version_mismatch() {
            if ! grep -q "GIT_ENV_VERSION=\"${version}\"" "${TEMP_FILE}"; then
                echo -ne "\e[1m\e[93m"
                echo "Updater: version mismatch in downloaded file!"
                echo "Expected: $version"
                echo "If you are the user, please wait until it gets fixed."
                echo "If you are the maintainer (Bashh), go fix that you forgetful bitch."
                echo -ne "\e[0m"

                grep -m1 GIT_ENV_VERSION "$TEMP_FILE"

                rm -f "$TEMP_FILE"
                return 1
            fi
        }

        broken_version_check(){
            if bash -n ${TEMP_FILE}; then
                echo -ne "\e[1m\e[93m"
                echo "This version is broken. Either you're using outdated Bash version or I made a mistake on writing. Try updating and try again later?"
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

            sanity_version_mismatch  || return 1
            log "Version sanity check passed"

            broken_version_check || return 1
            log "Functionality/syntax test returned 0"

            (chmod +x $TEMP_FILE && bash -n $TEMP_FILE) || (echo "Script check failed (see above)." && return 1)

            if [[ ! -s "$TEMP_FILE" ]]; then
                echo "Updater: downloaded file is empty, aborting."
                log "Downloaded file empty, aborting update"
                rm -f "$TEMP_FILE"
                return 1
            fi

            log "Overwriting script with new version"
            cat "$TEMP_FILE" > "$SCRIPT_PATH" && rm -f "$TEMP_FILE"

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

    main_updater() {
        local response

        echo
        echo "New update is available!"
        echo
        echo "${GIT_ENV_VERSION} -> ${changelog_output}"
        echo

        log "Prompting user for update (current=$GIT_ENV_VERSION, new=$version)"
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
        connection_checker && fetch

        if [[ -n "$version" && "$GIT_ENV_VERSION" != "$version" ]]; then
            log "Update available: $GIT_ENV_VERSION -> $version"
            return 255
        else
            log "No updates (current=$GIT_ENV_VERSION)"
            return 0
        fi
    }

    # Run synchronously for now so we can trust exit code
    status=0
    main_checker || status=$?

    if [[ $status -eq 255 ]]; then
        main_updater
    fi
}

