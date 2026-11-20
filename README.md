# jScripts

A personal command-line toolset for macOS, with Linux support where it makes sense. Every tool is a small Bash script named `j<Name>`, such as `jPush` or `jExtract`. The `j` command ties them together: it finds scripts, shows their help and lets you pick one.

---

## Setup

Clone the repo and add its folder to your `PATH`. The scripts run from there as they are, with no install step:

```bash
git clone https://github.com/jorisvandijk/scripts.git ~/Git/scripts
export PATH="$HOME/Git/scripts:$PATH"
```

For the interactive picker, source the zsh integration in your `.zshrc`:

```zsh
source ~/Git/scripts/j.zsh
```

Running `j` with no arguments then opens a picker, and the script you choose lands in your prompt (for example `jRename `), ready to run with or without arguments.

> If `j` doesn't respond, run `type -a j`: a shell function may be
> shadowing it. `command j` calls the script directly.

Most scripts need other programs, such as `fzf` or `bat`. Each script lists them on its `Dependencies:` line and tells you when one is missing.

---

## Using `j`

```
j                    Open the interactive script picker (requires fzf)
j list               List all scripts with their one-line descriptions
j man <jName>        Show the manual for a script
j new <jName>        Create a new script
j newman <jName>     Create a manual page for a script
j help               Show the command list
```

Every script also takes `-h`/`--help` for a short usage summary and `-v`/`--version` for its version.

---

## Configuration: `j.vars`

Personal values, such as server users, paths and URLs, live in `j.vars` in the repo root. `j` loads it on every run. Set the values for the scripts you use. A script that needs a value you haven't set tells you which one.

| Variable | Used by | Purpose |
|---|---|---|
| `JVAR_HOMELAB_USER` | jGog, jSync | User SSH access to homelab |
| `JVAR_HOMELAB_ROOT` | jLxc | Root SSH access to homelab (Proxmox) |
| `JVAR_GOG_PATH` | jGog | GOG download directory on homelab |
| `JVAR_SERVER_ROOT` | jSync | Root data directory on homelab |
| `JVAR_HUGO_SITE_DIR` | jBlog, jHugoHelper | Local Hugo site directory |
| `JVAR_HUGO_URL` | jBlog | Hugo dev server URL |
| `JVAR_NEWREPO_CONFIG` | jNewRepo | Path to the newrepo token config file |
| `JVAR_GIT_USERNAME` | jNewRepo | Git forge username |
| `JVAR_REPOS_DIR` | jRepos | Base directory scanned for git repos |
| `JVAR_DOTFILES_DIR` | jTidy | Dotfiles repository path |
| `JVAR_NOTE_TITLE` | jNote | Title of the Apple Notes note to open |

---

## Scripts

| Script | Description |
|---|---|
| `j` | jScripts shared library and CLI tooling |
| `jBlog` | Write and publish a Hugo blog post |
| `jEject` | Eject a mounted drive |
| `jFindApp` | Search for an app across App Store, Homebrew, and Nix |
| `jExtract` | Smart archive extraction |
| `jFlac2Alac` | Batch-convert FLAC files to Apple Lossless (ALAC) |
| `jGog` | Browse GOG library and download games locally or to homelab |
| `jHeic2Png` | Convert HEIC images to PNG |
| `jHugoHelper` | Hugo site helper: server, new post, new status |
| `jList` | Directory listing with eza |
| `jLxc` | Toggle Proxmox LXC containers on/off |
| `jNewRepo` | Initialize a local git repo and create it on GitHub, GitLab, Codeberg, and Bitbucket |
| `jNote` | Launch or raise Apple Notes and open a specific note |
| `jOpenFzf` | Select files with bat preview and open in micro |
| `jPush` | Stage, commit, and push to Git |
| `jRename` | Rename files in current directory: lowercase, spaces and underscores to hyphens |
| `jRepos` | Show git status of all repositories in ~/git |
| `jSync` | Interactively sync files to or from a server via rsync |
| `jTidy` | Audit the macOS home directory and guide an interactive cleanup |
| `jTube` | Resolve YouTube channel IDs and output Nix RSS feed entries |

Run `j list` for live descriptions parsed from each script's header.

---

## License

Unless otherwise noted, all files in this repository are licensed under the MIT license.

You are free to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the software, with or without modification, provided the original copyright notice and this permission notice are included.

[MIT License](https://opensource.org/licenses/MIT)
