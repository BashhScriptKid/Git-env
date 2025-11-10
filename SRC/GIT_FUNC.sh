#------------------------------------------------------------------------------
# Git Repository Functions
#------------------------------------------------------------------------------

# Parse current Git branch
parse_git_branch() {
    local branch_list
    branch_list=$(git branch 2>/dev/null) || return 1

    if [[ -n "${branch_list}" ]]; then
        echo "${branch_list}" | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
    else
        return 1
    fi
}

# Display Git repository status
display_git_status() {
    local branch
    branch=$(parse_git_branch) || branch='None (Not in git repository.)'

    echo "On branch ${branch}"
    git status 2>/dev/null || echo "Status undefined."
}

# Check if current directory is in a Git repository
check_git_repository() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        if [[ "${NOT_GitDir}" != "1" ]]; then
            echo -e "\e[93m\e[1mWarning: Not in a Git repository."
            echo -e "Type 'init' to create a new repository in this directory.\e[0m"
            NOT_GitDir=1
        fi
        return 1
    else
        NOT_GitDir=0
        return 0
    fi
}

