#!/usr/bin/env bash
#	j 3.7
#	j-scripts shared library and CLI tooling
#	Dependencies: none
#	Keywords: library, cli, help, list, new, man
#	Usage: j <command> [args]
#
#	By Joris van Dijk | Jorisvandijk.com
#	Licensed under the MIT license

J_RED='' J_GREEN='' J_YELLOW='' J_RESET='' J_BOLD='' J_DIM='' J_CYAN='' J_PURPLE=''
[[ -t 1 && -z "${NO_COLOR:-}" ]] && {
    J_RED=$'\033[0;31m'
    J_GREEN=$'\033[0;32m'
    J_YELLOW=$'\033[0;33m'
    J_PURPLE=$'\033[0;35m'
    J_RESET=$'\033[0m'
    J_BOLD=$'\033[1m'
    J_DIM=$'\033[2m'
    J_CYAN=$'\033[36m'
}

J_FZF_STYLE=(
    --style=full:rounded
    --color='prompt:-1,pointer:green,marker:yellow,hl:green,hl+:green,input-label:magenta:bold'
    --reverse
    --height=100%
    --info=inline-right
    --no-bold
    --no-hscroll
    --tabstop=14
    --padding=0,0,0,0
)

_j_cap() { local text="$*"; printf '%s' "${text^}"; }

j::info()  { printf "${J_GREEN}[INFO]${J_RESET} %s\n"     "$(_j_cap "$*")"; }
j::warn()  { printf "${J_YELLOW}[WARNING]${J_RESET} %s\n" "$(_j_cap "$*")" >&2; }
j::error() { printf "${J_RED}[ERROR]${J_RESET} %s\n"      "$(_j_cap "$*")" >&2; }
j::die()   { j::error "$*"; exit 1; }
j::row()   { printf "${1}%-20s %s${J_RESET}\n" "$2" "$3"; }

j::require() {
    local prog
    for prog in "$@"; do
        command -v "$prog" &>/dev/null || j::die "Required program $prog is not installed"
    done
}

j::os() {
    case "$OSTYPE" in
        darwin*) echo "macos" ;;
        linux*)  echo "linux" ;;
        *)       j::die "Unsupported OS: $OSTYPE" ;;
    esac
}

j::msg()    { printf "%s\n" "$*"; }
j::prompt() { printf "${J_BOLD}%s${J_RESET} " "$*"; }
j::confirm() {
    local question="$1" default="$2"
    local hint answer
    [[ "$default" == "Y" ]] && hint="[Y/n]" || hint="[y/N]"
    while true; do
        j::prompt "$question $hint"
        read -r answer
        case "${answer:-$default}" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
        esac
    done
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
    local lines
    mapfile -n 2 -t lines < "$script"
    printf '%s\n' "${lines[1]#$'#\t'}"
}

j::pick() {
    local prompt="$1" mode="$2"
    j::require fzf
    local multi_flag=()
    [[ "$mode" == "multi" ]] && multi_flag=(-m)
    fzf "${multi_flag[@]}" "${J_FZF_STYLE[@]}" \
        --prompt="$prompt: " \
        --input-label=" jSuite · ${0##*/} "
}

j::pick_table() {
    local prompt="$1" col_spec="$2" mode="$3" preview="${4:-}"
    j::require fzf
    local multi_flag=()
    [[ "$mode" == "multi" ]] && multi_flag=(-m)
    local args=("${multi_flag[@]}" --ansi --delimiter=$'\t' --with-nth="$col_spec"
                --prompt="$prompt: "
                --input-label=" jSuite · ${0##*/} "
                "${J_FZF_STYLE[@]}")
    [[ -n "$preview" ]] && args+=(--preview="$preview" --preview-window=right:50%:wrap)
    fzf "${args[@]}"
}

j::pick_files() {
    local prompt="${1:-Files}"
    j::require fzf bat
    fzf -m "${J_FZF_STYLE[@]}" \
        --prompt="$prompt: " \
        --input-label=" jSuite · ${0##*/} " \
        --preview="bat --color=always {}" \
        --preview-window=right:55%:wrap
}

j::show_man() {
    local name="$1"
    local script_dir; script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    local man_file="${script_dir}/man/${name}.txt"
    [[ ! -f "$man_file" ]] && j::die "No man page for ${name}"
    ${PAGER:-less} "$man_file"
}

_j_extract_section() {
    local file="$1" section="$2"
    local found=false line
    while IFS= read -r line; do
        [[ "$line" == "$section" ]] && { found=true; continue; }
        [[ "$found" == true && "$line" =~ ^[A-Z]+$ ]] && break
        [[ "$found" == true ]] && printf '%s\n' "$line"
    done < "$file"
}

j::help() {
    local name="$1"
    local script_dir; script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    local man_file="${script_dir}/man/${name}.txt"
    [[ ! -f "$man_file" ]] && j::die "No help available for ${name}"
    _j_extract_section "$man_file" "SYNOPSIS"
}

[[ "${BASH_SOURCE[0]}" != "${0}" ]] && return 0

_j_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P
}

_j_read_desc() {
    local script="$1" lines
    mapfile -n 3 -t lines < "$script"
    printf '%s' "${lines[2]#$'#\t'}"
}

_j_read_keywords() {
    local man_file="$1"
    [[ -f "$man_file" ]] || return 0
    local result="" trimmed line
    while IFS= read -r line; do
        [[ "$line" =~ [^[:space:]] ]] || continue
        read -r trimmed <<< "$line"
        result="${result:+$result }$trimmed"
    done < <(_j_extract_section "$man_file" "KEYWORDS")
    [[ -n "$result" ]] && printf '%s\n' "$result"
}

_j_list() {
    local script_dir; script_dir="$(_j_script_dir)"
    local script name desc
    for script in "${script_dir}"/*; do
        [[ -f "$script" && -x "$script" ]] || continue
        name="${script##*/}"
        [[ "$name" != "j" && ! "$name" =~ ^j[A-Z][a-zA-Z0-9]*$ ]] && continue
        desc="$(_j_read_desc "$script")"
        printf '%-22s - %s\n' "$name" "${desc:-(no description)}"
    done
}

_j_entries() {
    local script_dir="$1"
    local script name desc keywords kw_display
    for script in "${script_dir}"/*; do
        [[ -f "$script" && -x "$script" ]] || continue
        name="${script##*/}"
        [[ "$name" == "j" || ! "$name" =~ ^j[A-Z][a-zA-Z0-9]*$ ]] && continue
        desc="$(_j_read_desc "$script")"
        keywords="$(_j_read_keywords "${script_dir}/man/${name}.txt")"
        kw_display=""
        [[ -n "$keywords" ]] && kw_display=$'  \033[2m'"${keywords}"$'\033[0m'  # J_DIM unavailable: stdout captured by j.zsh
        printf '%s\t%s%s\n' "$name" "${desc:-(no description)}" "$kw_display"
    done
}

_j_launch() {
    local script_dir; script_dir="$(_j_script_dir)"
    j::require fzf

    local selection
    selection=$(
        _j_entries "$script_dir" | j::pick_table \
            'Pick a script' '1,2' single \
            "cat ${script_dir}/man/{1}.txt 2>/dev/null || printf 'No man page available.'"
    )
    [[ -z "$selection" ]] && return 0
    printf '%s ' "${selection%%$'\t'*}"
}

_j_new() {
    local name="$1"
    local script_dir; script_dir="$(_j_script_dir)"

    [[ -z "$name" ]]                            && j::die "Usage: j new <jName>"
    [[ "$(pwd -P)" != "$script_dir" ]]          && j::die "The program j must be run from ${script_dir}"
    [[ ! "$name" =~ ^j[A-Z][a-zA-Z0-9]*$ ]]     && j::die "Invalid name '${name}': must match ^j[A-Z][a-zA-Z0-9]*\$"
    [[ -f "${script_dir}/${name}" ]]            && j::die "Script '${name}' already exists"

    local tmpfile template
    tmpfile="$(mktemp)"
    trap 'rm -f "$tmpfile"' EXIT

    template='#!/usr/bin/env bash
#	SCRIPTNAME 1.0
#	One-line description
#	Dependencies: none
#	Keywords:
#	Usage: SCRIPTNAME [args]
#
#	By Joris van Dijk | Jorisvandijk.com
#	Licensed under the MIT license

source "$(dirname "${BASH_SOURCE[0]}")/j"

[[ "$1" == "--version" || "$1" == "-v" ]] && j::version "$0" && exit 0
[[ "$1" == "--help"    || "$1" == "-h" ]] && j::help "SCRIPTNAME" && exit 0'
    printf '%s\n' "${template//SCRIPTNAME/$name}" > "$tmpfile"

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
    trap 'rm -f "$tmpfile"' EXIT
    printf 'NAME\n    %s - \n\nSYNOPSIS\n    %s [options]\n\n    Options:\n      -h, --help      Show this help\n      -v, --version   Show version\n\nDESCRIPTION\n\nDescription here.\n\nEXAMPLES\n\n    %s\n        What this does.\n\nKEYWORDS\n\n    keyword1, keyword2\n' \
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
  j                    Launch the interactive script picker
  j list               List all j-scripts with descriptions
  j new <jName>        Create a new script (must run from scripts directory)
  j man <jName>        Show the man page for a script
  j newman <jName>     Create a new man page stub
  j help               Show this help text

  j --version | -v     Show version info
EOF
}

case "${1:-}" in
    list)         _j_list ;;
    new)          _j_new "${2:-}" ;;
    man)          _j_man "${2:-}" ;;
    newman)       _j_newman "${2:-}" ;;
    help)         _j_usage ;;
    --version|-v) j::version "$0" ;;
    --help|-h)    j::help "j" ;;
    '')           _j_launch ;;
    *)            j::die "Unknown command: $1 - run 'j help' for usage" ;;
esac
