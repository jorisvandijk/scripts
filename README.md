# Scripts

Personal CLI toolset for macOS (primary) and Linux. Every script is named
`j<CapitalWord>` (e.g. `jPush`, `jExtract`). A single central script, `j`,
acts as shared library and management CLI. No symlinks, no dispatchers.

---

## Setup

Scripts live at `~/git/scripts/` and are added to PATH directly:

```bash
export PATH="$HOME/git/scripts:$PATH"
```

> If `j` doesn't respond, run `type -a j` - a shell function (e.g. from
> autojump) may be shadowing the binary.

---

## `j` - shared library and CLI

Every script sources `j` unconditionally:

```bash
source "$(dirname "${BASH_SOURCE[0]}")/j"
```

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

Every script opens with this exact block. Lines 2–8 are tab-indented (`#\t`):

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

### Boilerplate

Immediately after the header:

```bash
source "$(dirname "${BASH_SOURCE[0]}")/j"

[[ "$1" == "--version" || "$1" == "-v" ]] && j::version "$0" && exit 0
[[ "$1" == "--help"    || "$1" == "-h" ]] && j::help "jName" && exit 0
```

Add a no-argument guard if the script takes no arguments:

```bash
[[ -n "$1" ]] && j::die "Usage: jName (no arguments)"
```

### Library functions

| Function | Behavior |
|---|---|
| `j::info "msg"` | Green `[INFO]` to stdout |
| `j::warn "msg"` | Yellow `[WARNING]` to stdout |
| `j::error "msg"` | Red `[ERROR]` to stderr |
| `j::die "msg"` | Red `Error:` to stderr, exit 1 |
| `j::version "$0"` | Print line 2 of the script header |
| `j::help "jName"` | Print the SYNOPSIS section from `man/jName.txt` |
| `j::show_man "jName"` | Open `man/jName.txt` in `$PAGER` |
| `j::row "$color" "name" "label"` | Print a color-coded `%-20s` aligned row (for tabular output) |
| `j::require prog [prog2 ...]` | Die if any listed program is not in PATH |
| `j::os` | Print `macos` or `linux`; die on unsupported OS |
| `j::edit_or_discard file` | Open file in `$EDITOR`; remove it and return 1 if unchanged, return 0 if changed |

Colors available directly in any script: `$J_RED`, `$J_GREEN`, `$J_YELLOW`, `$J_RESET`, `$J_BOLD`, `$J_DIM`, `$J_CYAN`.

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
```

- `--help` (`j::help`) prints the SYNOPSIS section only.
- `j man jName` shows the full file.

### Versioning

- Start at `1.0`. Bump the minor version for each meaningful change.
- Version lives on line 2 of the header: `#	jName 1.2`.

### README entry

Add every new script to the `## Scripts` table below.

---

## Hardcoded locations

| What | Path |
|---|---|
| Scripts directory | `~/git/scripts/` |
| Man pages | `~/git/scripts/man/` |
| Git repos scanned by jRepos | `~/git/` |
| Nix config (jNix) | `~/Git/nix/` |
| Gojo project (jGojo) | `~/git/gojo/` |
| Hugo site (jHugoHelper) | `~/git/website/` |
| jNewRepo API config | `~/git/documents/newrepo/config` |
| Dotfiles repo (jTidy) | `~/git/macbook/` |

---

## Scripts

| Script | Description |
|---|---|
| `j` | j-scripts shared library and CLI tooling |
| `jEject` | Eject a mounted drive via fzf |
| `jFindApp` | Search for an app across App Store, Homebrew, and Nix |
| `jExtract` | Smart archive extraction |
| `jFlac2Alac` | Batch-convert FLAC files to Apple Lossless (ALAC) |
| `jGojo` | Build gojo for Linux and deploy it to the gojo server |
| `jHeic2Png` | Convert HEIC images to PNG |
| `jHugoHelper` | Hugo site helper: server, new post, new status |
| `jList` | Directory listing with eza |
| `jNewRepo` | Initialize a local git repo and create it on GitHub, GitLab, Codeberg, and Bitbucket |
| `jNix` | Navigate and edit nix configuration files |
| `jOpenFzf` | Select files with fzf and open them in micro |
| `jPush` | Stage, commit, and push to Git |
| `jRepos` | Show git status of all repositories in ~/git |
| `jTidy` | Audit the macOS home directory and guide an interactive cleanup |

Run `j list` for live descriptions parsed from each script's header.

---
