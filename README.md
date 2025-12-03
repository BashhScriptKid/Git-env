# Git-env
(Name is not final; suggestion open)
## A pseudo-shell environment for Git


> [!IMPORTANT]
> The project currently only focuses on mono-master branch. I see no reason to modularise it further yet.

## Introduction
This is a pseudo-shell environment for Git. It allows you to run Git commands in a ctl-shell-like environment.

This is something I've wrote in Bash from scratch out of frustration. This script tries to avoid as many dependencies as possible. It is designed to be as lightweight, and flexible as possible.

This project is under a (not final) custom WTFPL license with attribution requirement.

## Installation

As of now, Git-env is a monolithic script that you can run directly from the command line.
Modular repository is planned, but only after clear sign of interest from the community. (you can get started by finishing the pseudo-assembler)

### You can install by simply running the following command:
Locally:
```sh
curl 'https://raw.githubusercontent.com/BashhScriptKid/Git-env/refs/heads/master/git-shellenv.sh' >> /usr/local/bin/git-env
```
Globally:
```sh
curl 'https://raw.githubusercontent.com/BashhScriptKid/Git-env/refs/heads/master/git-shellenv.sh' >> /usr/bin/git-env
```

Dependencies:
- Git
- Bash 4+
- GNU Coreutils

Optional Dependencies:
- Lazygit
- gh
