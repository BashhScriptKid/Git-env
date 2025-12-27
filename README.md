# Igitari
*A kindly powerful Git companion*

> [!IMPORTANT]
> The project currently only focuses on mono-master branch. I see no reason to modularise it further yet.

## Introduction
Igitari is a Git shell companion born from the simple desire to type 'git' less often. It's designed to make Git approachable without sacrificing its power — because you shouldn't have to fight your tools to do great work.

Written in Bash from scratch, Igitari tries to avoid as many dependencies as possible. It is lightweight, portable, and flexible, with a philosophy of being "kindly powerful": helping you explore Git's capabilities while watching your back.

This project is licensed under AGPL-3.0-or-later.

## Philosophy: Kindly Powerful
Igitari aims to:
- **Reduce friction** in daily Git workflows
- **Provide safety nets** for common pitfalls
- **Stay out of your way** when you know what you're doing
- **Remain lightweight** and dependency-free


## Features
- Interactive Git shell with intelligent tab completion
- Dynamic prompt:
  - Branch name
  - Repository status
  - Dirty state markers
- Shell command execution (prefix with `>`)
- Operator support (`&&`, `||`, `;`)
- LazyGit integration (Ctrl+G when available)
- Web repository opening (`openweb` command)
- Self-updating system
- Cross-platform (Linux, macOS, Windows WSL)

> [!WARNING]
> Igitari is primarily tested on Linux.
> Behavior on other platforms may vary—please report issues if you encounter discrepancies.

## Installation

### Quick Install
```sh
curl -L https://github.com/BashhScriptKid/igitari/raw/master/igitari.sh -o ~/.local/bin/igitari
chmod +x ~/.local/bin/igitari
```

### Development Install
```sh
git clone https://github.com/BashhScriptKid/igitari.git
cd igitari
ln -s igitari.sh ~/.local/bin/igitari
```

### Global Install
```sh
sudo curl -L https://github.com/BashhScriptKid/igitari/raw/master/igitari.sh -o /usr/bin/igitari
sudo chmod +x /usr/bin/igitari
```

### Dependencies
**Required:**
- Git
- Bash 4+
- GNU Coreutils

**Optional:**
- Lazygit (for TUI integration)
- FZF (For FZF-based query for commits, stashes, etc)

## Usage
Start Igitari:
```sh
igitari
```

Get help:
```sh
igitari -h
```

Start in a specific directory:
```sh
igitari -p /path/to/repo
```

Enable verbose logging:
```sh
igitari --verbose
```

---

Upon entering, you'll see:
```
Entering Igitari (Hi!). Press Ctrl+D or type 'exit' to quit.
Prefix commands with '>' to execute shell commands
Press Ctrl+G to launch LazyGit

[.../awesome-repo/ (master*)]igitari>
```

The prompt shows:
- Repository path (compressed for readability)
- Current branch
- Status markers: `*` (unstaged), `^` (staged), `_` (stash exists)

### Basic Usage
Run Git commands without typing `git`:
```
[.../awesome-repo/ (master)]igitari> status
On branch master
Your branch is up to date with 'origin/master'.

nothing to commit, working tree clean
```

Run shell commands (prefix with `>`):
```
[.../awesome-repo/ (master)]igitari> > ls
README.md  package.json  src/
```

Open repository in browser:
```
[.../awesome-repo/ (master)]igitari> openweb origin
Opened: https://github.com/user/repo
```

### Operator Support
```
[.../awesome-repo/ (master)]igitari> status && > ls -la
[.../awesome-repo/ (master)]igitari> add . || echo "Failed to add files"
```

## Uninstallation
```sh
rm $(which igitari)
```

## License
AGPL-3.0-or-later © 2025 BashhScriptKid

Igitari is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

See the full license in the script header or at https://www.gnu.org/licenses/
## Why AGPL?
Igitari uses AGPL-3.0-or-later to ensure it remains free and open. If you modify and distribute Igitari (including as part of a web service), you must share your changes. This prevents SaaS exploitation while encouraging community improvements.

---
Hope this is useful!
