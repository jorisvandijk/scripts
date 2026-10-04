#!/usr/bin/env zsh
#	j.zsh 1.0
#	Zsh shell integration for jScripts
#	Source this file from ~/.zshrc: source ~/git/scripts/j.zsh

j() {
    [[ $# -gt 0 ]] && { command j "$@"; return $?; }
    local s; s="$(command j)"
    [[ -n "$s" ]] && print -z "$s"
}
