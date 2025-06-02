#!/usr/bin/env bash

dir="${XDG_CONFIG_HOME}/tmux/plugins/tpm/bindings"

# basic information
session="$(tmux display-message -p '#S')"
window="$(tmux display-message -p '#W')"
client="$(tmux display-message -p '#{client_name}')"
pane="$(tmux display-message -p '#{pane_id}')"

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
