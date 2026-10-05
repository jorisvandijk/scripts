# jScripts

Personal CLI toolset for macOS (primary) and Linux. Every script is named
`j<CapitalWord>` (e.g. `jPush`, `jExtract`). A single central script, `j`,
acts as shared library and management CLI. No symlinks, no dispatchers.

---

## Setup

Scripts live at `~/git/scripts/` and are added to PATH directly:

```bash
export PATH="$HOME/git/scripts:$PATH"
```

To make `j` (no args) open the interactive picker and insert the selection
into your prompt buffer, source the included zsh integration file:

```zsh
source ~/git/scripts/j.zsh
```

Selecting a script in the picker then places its name (e.g. `jRename `) in
the prompt, ready to run with or without arguments.

> If `j` doesn't respond, run `type -a j` — a shell function may be
> shadowing the binary. `command j` bypasses shell functions and calls
> the binary directly.

---

## `j` - shared library and CLI

Every script sources `j` unconditionally:

```bash
source "$(dirname "${BASH_SOURCE[0]}")/j"
```

### CLI commands

```
j                    Open the interactive script picker (requires fzf)
j list               List all scripts with their one-line descriptions
j new <jName>        Create a new script
j man <jName>        Show the man page for a script
j newman <jName>     Create a new man page stub for a script
j help               Show the command list
```

---

## Creating a new script

```bash
j new jMyTool
```

`j new` validates the name, generates a compliant template, opens `$EDITOR`,
and only saves the file (with `chmod +x`) if you actually changed something.

For naming, header format, boilerplate, man page requirements, and code style
see [Script requirements](#script-requirements) below.

---

## Script requirements

Everything needed to write a compliant j-script, in one place.

### Naming

`^j[A-Z][a-zA-Z0-9]*$` - lowercase `j`, uppercase first letter, alphanumeric rest. No hyphens, no underscores.

### Header

Every script opens with this exact block. Lines 2–9 are tab-indented (`#\t`):

```bash
#!/usr/bin/env bash
#	jName 1.0
#	One-line description
#	Dependencies: dep1, dep2
#	Keywords: word1, word2, word3
#	Usage: jName [args]
#
#	By Joris van Dijk | Jorisvandijk.com
#	Licensed under the MIT license
```

### Boilerplate

Immediately after the header:

```bash
source "$(dirname "${BASH_SOURCE[0]}")/j"

[[ "$1" == "--version" || "$1" == "-v" ]] && j::version "$0" && exit 0
[[ "$1" == "--help"    || "$1" == "-h" ]] && j::help "jName" && exit 0
```

> **Exception — `j` itself:** The shared library cannot source itself.
> It handles `--version` and `--help` in its bottom `case` statement and
> guards the CLI section with `[[ "${BASH_SOURCE[0]}" != "${0}" ]] && return 0`.
> This is the only permitted deviation from the boilerplate form.

Add a no-argument guard if the script takes no arguments:

```bash
[[ -n "$1" ]] && j::die "Usage: jName (no arguments)"
```

### Library functions

| Function | Behavior |
|---|---|
| `j::info "msg"` | Green `[INFO]` to stdout |
| `j::warn "msg"` | Yellow `[WARNING]` to stderr |
| `j::error "msg"` | Red `[ERROR]` to stderr |
| `j::die "msg"` | Red `[ERROR]` to stderr, exit 1 |
| `j::version "$0"` | Print line 2 of the script header |
| `j::help "jName"` | Print the SYNOPSIS section from `man/jName.txt` |
| `j::show_man "jName"` | Open `man/jName.txt` in `$PAGER` |
| `j::row "$color" "name" "label"` | Print a color-coded `%-20s` aligned row (for tabular output) |
| `j::require prog [prog2 ...]` | Die if any listed program is not in PATH |
| `j::require_vars JVAR_ [JVAR_2 ...]` | Die with a clear message if any listed `JVAR_` variable is unset |
| `j::os` | Print `macos` or `linux`; die on unsupported OS |
| `j::edit_or_discard file` | Open file in `$EDITOR`; remove it and return 1 if unchanged, return 0 if changed |
| `j::msg "msg"` | Print message to stdout with no prefix |
| `j::prompt "text"` | Print bold inline prompt to stdout, no trailing newline |
| `j::confirm "question" Y\|N` | Prompt for y/n, reprompt on invalid input, return 0 if confirmed. Second argument sets the default and must be `Y` or `N` |
| `j::pick "prompt" single\|multi` | Interactive line picker (fzf). Reads from stdin. |
| `j::pick_table "prompt" "col_spec" single\|multi ["preview_cmd"]` | Tab-delimited table picker. `col_spec` is a `--with-nth` spec e.g. `"1,2"`. Optional fourth arg enables a right-side preview pane. |
| `j::pick_files ["prompt"]` | Multi-select file picker with bat preview. Prompt defaults to `Files`. |

All three pickers share a common house style (`J_FZF_STYLE`) defined in `j`. The input label is set automatically to `jScripts · <script-name>`. Pass a bare word as the prompt — the helper appends the colon.

Colors and styles available directly in any script:

| Variable | Effect |
|---|---|
| `$J_RED` | Red text |
| `$J_GREEN` | Green text |
| `$J_YELLOW` | Yellow text |
| `$J_CYAN` | Cyan text |
| `$J_PURPLE` | Purple text |
| `$J_BOLD` | Bold text |
| `$J_DIM` | Dimmed text |
| `$J_RESET` | Reset all formatting |

### Code style

1. **Every function operates at a single level of abstraction** *(SLAP, Clean Code Ch. 3).* Extract when a block of code requires "zooming in" to a lower level than its surroundings; leave it inline when it reads at the same level as the rest of the function. Call frequency is not the criterion.
   - Single responsibility follows naturally from this: a function that stays at one level of abstraction automatically does one thing.
   - Extract a helper only when it abstracts a genuinely lower level or is called more than once. Trivial one-off logic at the same abstraction level stays inline.
2. **Guard clauses first, happy path last** - early-exit on failure at the top; success flows at the bottom. No if/else chains.
3. **No nesting deeper than 3 levels.**
4. **Never use elif** - When reaching more than a two-way if-else, use a case instead.
5. **Capitalize user-facing messages** - The first word of every `j::info`, `j::warn`, `j::error`, and `j::die` message is capitalized. The library enforces this as a fallback via `_j_cap`.
6. **No single-letter variables** - All variable names must be descriptive. `x`, `y`, `i`, `n`, etc. are not allowed, even as loop indices or temporaries.
7. **Prefix internal functions with `_`** - Every function defined inside a script is prefixed with `_`. This distinguishes script-local helpers from library functions (`j::`) and shell built-ins.
8. **Variable naming** - Script-level (global) variables use UPPERCASE. Variables declared inside a function use `local` and are lowercase. Loop variables at script level follow the global convention: UPPERCASE.
9. **Prefer builtins over external commands** - Use `$(<file)` instead of `$(cat file)` to read a file into a variable. Avoid spawning a subprocess when a bash builtin achieves the same result.
10. **No hardcoded personal values** - IPs, paths, usernames, and any other environment-specific value belong in `j.vars` and must be referenced via `JVAR_` variables. Call `j::require_vars` to guard required variables at script start.

### Man page

Every script requires `man/jName.txt`. Sections must appear in this order:

```
NAME
    jName - short description

SYNOPSIS
    jName [options] <arg>

    Options:
      -h, --help      Show this help
      -v, --version   Show version

DESCRIPTION

Longer explanation of what the script does.

EXAMPLES

    jName foo
        What this does.

KEYWORDS

    word1, word2, word3
```

- `--help` (`j::help`) prints the SYNOPSIS section only.
- `j man jName` shows the full file.
- `KEYWORDS` are used by the `j` interactive picker for fuzzy search — include alternative names and task descriptions a user might type.

### Versioning

All scripts share the same **major** version as `j`. The minor is per-script and increments by 1 for each meaningful change. Minor is a plain integer — `1.9` goes to `1.10`, not `2.0`.

- **Major bump:** declared when a significant round of changes advances the whole suite (e.g. a code review touching many scripts, a breaking change to the `j` library). All scripts move to the new `MAJOR.0` together — the minor counter resets to `0` regardless of where it was (`2.18` becomes `3.0`, not `3.18`).
- **Minor bump:** any meaningful change to a specific script — bug fix, improvement, or new feature. Only the changed script's minor increments.
- Version lives on line 2 of the header: `#	jName 3.2`.

### README entry

Add every new script to the `## Scripts` table below.

---

## j.vars

`j.vars` lives in the repo root and is sourced automatically by `j` on every script run. It holds all environment-specific values for the suite. Never hardcode personal values in scripts — define them here and reference them via their `JVAR_` name.

To guard required variables at the start of a script:

```bash
j::require_vars JVAR_HOMELAB_USER JVAR_REPOS_DIR
```

This dies with a clear message if any listed variable is unset, pointing the user to `j.vars`.

### Available variables

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
