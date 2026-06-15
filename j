#!/usr/bin/env bash
#	j 1.0
#	j-scripts shared library and CLI tooling
#	Dependencies: none
#	Usage: j <command> [args]
#
#	By Joris van Dijk | Jorisvandijk.com
#	Licensed under the MIT license

# ── Shared library (available when sourced or executed) ──────────────────────

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    J_RED='\033[0;31m'
    J_GREEN='\033[0;32m'
    J_YELLOW='\033[0;33m'
    J_RESET='\033[0m'
else
    J_RED='' J_GREEN='' J_YELLOW='' J_RESET=''
fi

j::info()  { printf "${J_GREEN}[INFO]${J_RESET} %s\n" "$*"; }
j::warn()  { printf "${J_YELLOW}[WARNING]${J_RESET} %s\n" "$*"; }
j::error() { printf "${J_RED}[ERROR]${J_RESET} %s\n" "$*" >&2; }
j::die()   { printf "${J_RED}Error: %s${J_RESET}\n" "$*" >&2; exit 1; }

j::version() {
    local script="$1"
    [[ -f "$script" ]] || j::die "j::version: file not found: $script"
    sed -n '2p' "$script" | sed 's/^#\t*//'
}

j::show_man() {
    local name="$1"
    local script_dir; script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    local man_file="${script_dir}/man/${name}.txt"
    [[ ! -f "$man_file" ]] && j::die "no man page for ${name}"
    ${PAGER:-less} "$man_file"
}

j::help() {
    local name="$1"
    local script_dir; script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    local man_file="${script_dir}/man/${name}.txt"
    [[ ! -f "$man_file" ]] && j::die "no help available for ${name}"
    awk '/^SYNOPSIS$/{found=1; next} found && /^[A-Z][A-Z]/{exit} found{print}' "$man_file"
}

# ── CLI (only when executed directly) ────────────────────────────────────────

[[ "${BASH_SOURCE[0]}" != "${0}" ]] && return 0

_j_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P
}

_j_list() {
    local script_dir; script_dir="$(_j_script_dir)"
    local script name desc
    for script in "${script_dir}"/*; do
        [[ -f "$script" && -x "$script" ]] || continue
        name="$(basename "$script")"
        [[ "$name" != "j" && ! "$name" =~ ^j[A-Z][a-zA-Z0-9]*$ ]] && continue
        desc="$(sed -n '3p' "$script" | sed 's/^#\t//')"
        printf '%-22s — %s\n' "$name" "${desc:-(no description)}"
    done
}

_j_new() {
    local name="$1"
    local script_dir; script_dir="$(_j_script_dir)"

    [[ -z "$name" ]]                            && j::die "usage: j new <jName>"
    [[ "$(pwd -P)" != "$script_dir" ]]          && j::die "j new must be run from ${script_dir}"
    [[ ! "$name" =~ ^j[A-Z][a-zA-Z0-9]*$ ]]    && j::die "invalid name '${name}': must match ^j[A-Z][a-zA-Z0-9]*\$"
    [[ -f "${script_dir}/${name}" ]]            && j::die "${name} already exists"

    local tmpfile; tmpfile="$(mktemp)"

    sed "s/SCRIPTNAME/${name}/g" << 'TEMPLATE' > "$tmpfile"
#!/usr/bin/env bash
#	SCRIPTNAME 1.0
#	One-line description
#	Dependencies: none
#	Usage: SCRIPTNAME [args]
#
#	By Joris van Dijk | Jorisvandijk.com
#	Licensed under the MIT license

source "$(dirname "${BASH_SOURCE[0]}")/j"

[[ "$1" == "--version" || "$1" == "-v" ]] && j::version "$0" && exit 0
[[ "$1" == "--help"    || "$1" == "-h" ]] && j::help "SCRIPTNAME" && exit 0

# Available logging helpers (from j shared library):
#   j::info  "message"   — green  [INFO]
#   j::warn  "message"   — yellow [WARNING]
#   j::error "message"   — red    [ERROR]  (stderr)
#   j::die   "message"   — red    Error: … (stderr, exits 1)
#   j::help  "name"      — print HELP section from man/name.txt
TEMPLATE

    local before after
    before="$(<"$tmpfile")"
    "${EDITOR:-vi}" "$tmpfile"
    after="$(<"$tmpfile")"

    if [[ "$before" == "$after" ]]; then
        rm "$tmpfile"
        echo "No changes — file not created."
        return 0
    fi

    mv "$tmpfile" "${script_dir}/${name}"
    chmod +x "${script_dir}/${name}"
    echo "Created: ${script_dir}/${name}"
}

_j_man() {
    local name="$1"
    [[ -z "$name" ]] && j::die "usage: j man <jName>"
    j::show_man "$name"
}

_j_newman() {
    local name="$1"
    local script_dir; script_dir="$(_j_script_dir)"

    [[ -z "$name" ]]                          && j::die "usage: j newman <jName>"
    [[ ! -f "${script_dir}/${name}" ]]        && j::die "${name} not found in ${script_dir}"

    local man_file="${script_dir}/man/${name}.txt"
    [[ -f "$man_file" ]]                      && j::die "man page already exists: ${man_file}"

    local tmpfile; tmpfile="$(mktemp)"
    printf '%s\n\nNAME\n    %s — \n\nSYNOPSIS\n    %s [args]\n\nDESCRIPTION\n    \n\nHELP\n    Usage: %s [options]\n\n    Options:\n      -h, --help      Show this help\n      -v, --version   Show version\n' \
        "$name" "$name" "$name" "$name" > "$tmpfile"

    local before after
    before="$(<"$tmpfile")"
    "${EDITOR:-vi}" "$tmpfile"
    after="$(<"$tmpfile")"

    if [[ "$before" == "$after" ]]; then
        rm "$tmpfile"
        echo "No changes — man page not created."
        return 0
    fi

    mkdir -p "${script_dir}/man"
    mv "$tmpfile" "$man_file"
    echo "Created: ${man_file}"
}

_j_usage() {
    cat << 'EOF'
j — j-scripts shared library and CLI tooling

Usage:
  j list               List all j-scripts with descriptions
  j new <jName>        Create a new script (must run from scripts directory)
  j man <jName>        Show the man page for a script
  j newman <jName>     Create a new man page stub

  j --version | -v     Show version info
EOF
}

case "${1:-}" in
    list)         _j_list ;;
    new)          _j_new "${2:-}" ;;
    man)          _j_man "${2:-}" ;;
    newman)       _j_newman "${2:-}" ;;
    --version|-v) j::version "$0" ;;
    '')           _j_usage ;;
    *)            j::die "unknown command: $1 — run 'j' for usage" ;;
esac
