# Git-env
(Name is not final; suggestion open)
## A pseudo-shell environment for Git


> [!IMPORTANT]
> The project currently only focuses on mono-master branch. I see no reason to modularise it further yet.

## Introduction
This is a pseudo-shell environment for Git. It allows you to run Git commands in a ctl-shell-like environment.

This is something I've wrote in Bash from scratch out of frustration. This script tries to avoid as many dependencies as possible. It is designed to be as lightweight, and flexible as possible.

This project is under a (not final) custom WTFPL license with attribution requirement.

## Todo
The current scope is getting it as complete as possible, and also have the convenience of lazygit.

Local scope:
- [ ] Implement new upstream updater
- [ ] Add dirty branch marker support (and apply to prompt)
- [ ] Improve tab completion support

Lazygit porting scope:
- [ ] Implement `reword`
- [ ] Implement auto stashing
- [ ] Implement other alias shortcuts

## Installation

As of now, Git-env is a monolithic script that you can run directly from the command line.
Modular repository is planned, but only after clear sign of interest from the community. (you can get started by finishing the pseudo-assembler)

### You can install by simply running the following command:
Locally:
```sh
curl 'https://raw.githubusercontent.com/BashhScriptKid/Git-env/refs/heads/master/git-shellenv.sh' >> ~/.local/bin/git-env
```
Globally:
```sh
curl 'https://raw.githubusercontent.com/BashhScriptKid/Git-env/refs/heads/master/git-shellenv.sh' >> /usr/bin/git-env
```
If you want to use it while developing the script, you can link the sh path to your local bin directory:
```sh
git clone https://github.com/BashhScriptKid/Git-env.git
cd Git-env
ln -s git-shellenv.sh ~/.local/bin/git-env
```

Dependencies:
- Git
- Bash 4+
- GNU Coreutils

Optional Dependencies:
- Lazygit
- gh

## Uninstallation
Local:
```sh
rm /usr/local/bin/git-env
```
Global:
```sh
rm /usr/bin/git-env
```

## Usage
You can use Git-env by running the following command:
```sh
git-env
```

To get started with supported arguments, run the following command:
```sh
git-env -h
```

To start Git-env with a path (without cd first), run the following command:
```sh
git-env -P /path/to/repo
```

Debugging? Use this flag:
```sh
git-env --debug
```
---
Upon entering, you should see a prompt like this:
```
Entering Git shell. Press Ctrl+D or type 'exit' to quit.
Prefix commands with '>' to execute shell commands
Press Ctrl+G to launch LazyGit

[.../awesome-repo/ (master)]Git>

```

If you see this prompt:
```
[N/A]Git>
```
Then it means you're not in a Git repository. Restart with the -P flag or cd to a real repository first, or get started with `git init`.

You can simply run git commands without typing git:
```
[.../awesome-repo/ (master)]Git> status
On branch master
Your branch is up to date with 'origin/master'.

nothing to commit, working tree clean
[.../awesome-repo/ (master)]Git>
```

Although, it wouldn't mind if you already typed git:
```
[.../awesome-repo/ (master)]Git> git status
You're already in a Git shell!
On branch master
Your branch is up to date with 'origin/master'.

nothing to commit, working tree clean
[.../awesome-repo/ (master)]Git>
```

You can also run shell commands by typing '>'
```
[.../awesome-repo/ (master)]Git> > ls
README.md  git-env.sh
[.../awesome-repo/ (master)]Git>
```

Also supports binary operators!
```
[.../awesome-repo/ (master)]Git> status && > ls -l
On branch master
Your branch is up to date with 'origin/master'.

nothing to commit, working tree clean
total 8
-rw-r--r-- 1 user user  102 Mar 23 14:30 README.md
-rwxr-xr-x 1 user user 3600 Mar 23 14:30 git-env.sh
[.../awesome-repo/ (master)]Git> status && branch
On branch master
Your branch is up to date with 'origin/master'.

nothing to commit, working tree clean
* master
  branch2
[.../awesome-repo/ (master)]Git>
```
