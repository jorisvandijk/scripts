#!/usr/bin/env bash
#	j 1.4
#	j-scripts shared library and CLI tooling
#	Dependencies: none
#	Usage: j <command> [args]
#
#	By Joris van Dijk | Jorisvandijk.com
#	Licensed under the MIT license

J_RED='' J_GREEN='' J_YELLOW='' J_RESET='' J_BOLD='' J_DIM='' J_CYAN=''
[[ -t 1 && -z "${NO_COLOR:-}" ]] && {
    J_RED='\033[0;31m'
    J_GREEN='\033[0;32m'
    J_YELLOW='\033[0;33m'
    J_RESET='\033[0m'
    J_BOLD='\033[1m'
    J_DIM='\033[2m'
    J_CYAN='\033[36m'
}

_j_cap() { local text="$*"; printf '%s' "${text^}"; }

j::info()  { printf "${J_GREEN}[INFO]${J_RESET} %s\n"     "$(_j_cap "$*")"; }
j::warn()  { printf "${J_YELLOW}[WARNING]${J_RESET} %s\n" "$(_j_cap "$*")"; }
j::error() { printf "${J_RED}[ERROR]${J_RESET} %s\n"      "$(_j_cap "$*")" >&2; }
j::die()   { printf "${J_RED}Error: %s${J_RESET}\n"        "$(_j_cap "$*")" >&2; exit 1; }
j::row()   { printf "${1}%-20s %s${J_RESET}\n" "$2" "$3"; }

j::require() {
    local prog
    for prog in "$@"; do
        command -v "$prog" &>/dev/null || j::die "Required program $prog is not installed"
    done
}

j::os() {
    case "$(uname)" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        *)      j::die "Unsupported OS: $(uname)" ;;
    esac
}

j::edit_or_discard() {
    local filepath="$1"
    local before
    before="$(<"$filepath")"
    "${EDITOR:-vi}" "$filepath"
    [[ "$(<"$filepath")" == "$before" ]] && rm -f "$filepath" && return 1
    return 0
}

j::version() {
    local script="$1"
    [[ -f "$script" ]] || j::die "File not found: $script"
    sed -n '2s/^#\t*//p' "$script"
}

j::show_man() {
    local name="$1"
    local script_dir; script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    local man_file="${script_dir}/man/${name}.txt"
    [[ ! -f "$man_file" ]] && j::die "No man page for ${name}"
    ${PAGER:-less} "$man_file"
}

j::help() {
    local name="$1"
    local script_dir; script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    local man_file="${script_dir}/man/${name}.txt"
    [[ ! -f "$man_file" ]] && j::die "No help available for ${name}"
    awk '/^SYNOPSIS$/{found=1; next} found && /^[A-Z][A-Z]/{exit} found{print}' "$man_file"
}

[[ "${BASH_SOURCE[0]}" != "${0}" ]] && return 0

_j_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P
}

_j_list() {
    local script_dir; script_dir="$(_j_script_dir)"
    local script name desc
    for script in "${script_dir}"/*; do
        [[ -f "$script" && -x "$script" ]] || continue
        name="${script##*/}"
        [[ "$name" != "j" && ! "$name" =~ ^j[A-Z][a-zA-Z0-9]*$ ]] && continue
        desc="$(sed -n '3s/^#\t//p' "$script")"
        printf '%-22s - %s\n' "$name" "${desc:-(no description)}"
    done
}

_j_new() {
    local name="$1"
    local script_dir; script_dir="$(_j_script_dir)"

    [[ -z "$name" ]]                            && j::die "Usage: j new <jName>"
    [[ "$(pwd -P)" != "$script_dir" ]]          && j::die "The program j must be run from ${script_dir}"
    [[ ! "$name" =~ ^j[A-Z][a-zA-Z0-9]*$ ]]     && j::die "Invalid name '${name}': must match ^j[A-Z][a-zA-Z0-9]*\$"
    [[ -f "${script_dir}/${name}" ]]            && j::die "Script '${name}' already exists"

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
TEMPLATE

    j::edit_or_discard "$tmpfile" || { j::info "No changes - file not created"; return 0; }

    mv "$tmpfile" "${script_dir}/${name}"
    chmod +x "${script_dir}/${name}"
    j::info "Created: ${script_dir}/${name}"
}

_j_man() {
    local name="$1"
    [[ -z "$name" ]] && j::die "Usage: j man <jName>"
    j::show_man "$name"
}

_j_newman() {
    local name="$1"
    local script_dir; script_dir="$(_j_script_dir)"

    [[ -z "$name" ]]                          && j::die "Usage: j newman <jName>"
    [[ ! -f "${script_dir}/${name}" ]]        && j::die "Script '${name}' not found in ${script_dir}"

    local man_file="${script_dir}/man/${name}.txt"
    [[ -f "$man_file" ]]                      && j::die "Man page already exists: ${man_file}"

    local tmpfile; tmpfile="$(mktemp)"
    printf 'NAME\n    %s - \n\nSYNOPSIS\n    %s [options]\n\n    Options:\n      -h, --help      Show this help\n      -v, --version   Show version\n\nDESCRIPTION\n\nDescription here.\n\nEXAMPLES\n\n    %s\n        What this does.\n' \
        "$name" "$name" "$name" > "$tmpfile"

    j::edit_or_discard "$tmpfile" || { j::info "No changes - man page not created"; return 0; }

    mkdir -p "${script_dir}/man"
    mv "$tmpfile" "$man_file"
    j::info "Created: ${man_file}"
}

_j_usage() {
    cat << 'EOF'
j - j-scripts shared library and CLI tooling

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
    --help|-h)    j::help "j" ;;
    '')           _j_usage ;;
    *)            j::die "Unknown command: $1 - run 'j' for usage" ;;
esac
