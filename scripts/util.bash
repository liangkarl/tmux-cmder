#!/usr/bin/env bash

dir="${XDG_CONFIG_HOME}/tmux/plugins/tpm/bindings"

# basic information
session="$(tmux display-message -p '#S')"
window="$(tmux display-message -p '#W')"
client="$(tmux display-message -p '#{client_name}')"
pane="$(tmux display-message -p '#{pane_id}')"

# $1: option
# $2: default value
# Source: https://github.com/wfxr/tmux-fzf-url/blob/b8436ddcab9bc42cd110e0d0493a21fe6ed1537e/fzf-url.tmux#L11
tmux_get() {
  local value
  value="$(tmux show -gqv "$1")"
  [ -n "$value" ] && echo "$value" || echo "$2"
}

# https://github.com/tmux-plugins/tmux-copycat/blob/d7f7e6c1de0bc0d6915f4beea5be6a8a42045c09/scripts/helpers.sh#L12
cmd_exists() {
  command -v "$@" > /dev/null 2>&1
}

input_box() {
    echo -en | fzf --style=minimal --no-info --print-query --prompt "$*: " | head -n 1
}

list_win_all() {
    tmux list-windows -a -F "#S:#I - #W"
}

list_win_session() {
    tmux list-windows -F "[#S] #I:#W"
}

list_pane_all() {
    tmux list-panes -a -F "[#S] #I:#W/#P:#T"
}

list_pane_window() {
    tmux list-panes -F "[#S] #I:#W/#P:#T"
}

# @tmux-cmder-root='a'
# @tmux-cmder-key-0='b'
# @tmux-cmder-cmd-0='window'
# @tmux-cmder-key-...
parse_keybind() {
    local keys cmds
    local i key cmd
    keys=()
    cmds=()
    i=0

    key="$(tmux_get @tmux-cmder-root)"
    if [[ -n "$key" ]]; then
        tmux bind-key "$key" ""
    fi

    while :; do
        key="$(tmux_get @tmux-cmder-key-$i)"
        if [[ -z "$key" ]]; then
            break
        fi
        keys+="$key"

        cmd="$(tmux_get @tmux-cmder-cmd-$i)"
        cmds+="$cmd"

        i=$((i + 1))
    done
}
