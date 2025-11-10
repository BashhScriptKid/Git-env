# Display help information
show_help() {
    cat <<EOF
Git-env version ${GIT_ENV_VERSION}

A lightweight, interactive Git shell environment.
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
Git-env version ${GIT_ENV_VERSION}

A ctl-like interface for Git,
for when you don't want to keep typing 'git' in the terminal —
solving a problem that (mostly) doesn't exist.

It's an almost-no-dependency, lightweight, and flexible alternative to gitsh.

Written in Bash by BashhScriptKid
EOF 
#'
}

