# Scripts

Personal CLI toolset for macOS (primary) and Linux. Every script is named
`j<CapitalWord>` (e.g. `jPush`, `jExtract`). A single central script — `j` —
acts as shared library and management CLI. No symlinks, no dispatchers.

---

## Setup

Scripts live at `~/git/scripts/` and are added to PATH directly:

```bash
export PATH="$HOME/git/scripts:$PATH"
```

> If `j` doesn't respond, run `type -a j` — a shell function (e.g. from
> autojump) may be shadowing the binary.

---

## `j` — shared library and CLI

Every script sources `j` unconditionally:

```bash
source "$(dirname "${BASH_SOURCE[0]}")/j"
```

### Library functions (available to all scripts)

| Function | What it does |
|---|---|
| `j::info "msg"` | Green `[INFO]` to stdout |
| `j::warn "msg"` | Yellow `[WARNING]` to stdout |
| `j::error "msg"` | Red `[ERROR]` to stderr |
| `j::die "msg"` | Red `Error:` to stderr, then `exit 1` |
| `j::version "$0"` | Print line 2 of the calling script's header |
| `j::help "jName"` | Print the HELP section from `man/jName.txt` |
| `j::show_man "jName"` | Open `man/jName.txt` in `$PAGER` |

### CLI commands

```
j list               List all scripts with their one-line descriptions
j new <jName>        Create a new script (must cd to ~/git/scripts/ first)
j man <jName>        Show the man page for a script
j newman <jName>     Create a new man page stub for a script
```

---

## Creating a new script

```bash
cd ~/git/scripts
j new jMyTool
```

`j new` validates the name, generates the template below, opens `$EDITOR`,
and only saves the file (with `chmod +x`) if you actually changed something.

### Required header format

Every script starts with this block (tab-indented `#` lines):

```bash
#!/usr/bin/env bash
#	jName 1.0
#	One-line description
#	Dependencies: dep1, dep2
#	Usage: jName [args]
#
#	By Joris van Dijk | Jorisvandijk.com
#	Licensed under the MIT license
```

### Required boilerplate

```bash
source "$(dirname "${BASH_SOURCE[0]}")/j"

[[ "$1" == "--version" || "$1" == "-v" ]] && j::version "$0" && exit 0
[[ "$1" == "--help"    || "$1" == "-h" ]] && j::help "jName" && exit 0
```

### Naming rule

`^j[A-Z][a-zA-Z0-9]*$` — lowercase `j`, uppercase first letter, alphanumeric
rest. No hyphens, no underscores.

### Man pages

Man files live at `~/git/scripts/man/<jName>.txt`. Create a stub with
`j newman <jName>`. The `--help` flag prints only the `HELP` section;
`j man <jName>` shows the full file.

---

## Hardcoded locations

| What | Path |
|---|---|
| Scripts directory | `~/git/scripts/` |
| Man pages | `~/git/scripts/man/` |
| Git repos scanned by jRepos | `~/git/` |
| Hugo site (jHugoHelper) | `~/git/website/` |
| jNewRepo API config | `~/git/documents/newrepo/config` |
| Nexus API key (jNexusModlistDl, jNexusVerifyDir) | `~/.config/nexus-modlist-dl/config` |
| Nexus default download dir | `~/Downloads/skyrim-mods` |

---

## Scripts

| Script | Description |
|---|---|
| `j` | Shared library and CLI tooling |
| `jExtract` | Smart archive extraction |
| `jFlac2Alac` | Batch-convert FLAC files to Apple Lossless (ALAC) |
| `jGamesNostalgiaDl` | Interactive retro game downloader from GamesNostalgia |
| `jHeic2Png` | Convert HEIC images to PNG using macOS sips |
| `jHugoHelper` | Hugo site helper: server, new post, new status |
| `jList` | Enhanced directory listing with eza |
| `jNewRepo` | Init local git repo and create it on GitHub, GitLab, Codeberg, Bitbucket |
| `jNexusModlistDl` | Download Nexus mods from a markdown modlist |
| `jNexusVerifyDir` | Verify Nexus mod downloads against the API |
| `jOpenFzf` | Select files with fzf and open them in micro |
| `jPush` | Stage, commit, and push to Git |
| `jRepos` | Show git status of all repositories in ~/git |

Run `j list` for live descriptions parsed from each script's header.
