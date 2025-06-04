#!/usr/bin/env bash

# basic information
session="$(tmux display-message -p '#S')"
window="$(tmux display-message -p '#W')"
client="$(tmux display-message -p '#{client_name}')"
pane="$(tmux display-message -p '#{pane_id}')"
dir="$(dirname $0)"

# finder='fzf-tmux -p 40%,40% -- --reverse'

source ${dir}/menu.bash
source ${dir}/common.bash
source ${dir}/util.bash

main_menu=("clipboard" "keys" "tools" "plugin" "session" "window" "pane" "exit")
session_menu=("new" "kill" "switch" "detach" "rename" "info" "back" "exit")
win_menu=("swap" "break" "kill" "switch" "move" "rename" "link" "info" "back" "exit")
pane_menu=("rename" "swap" "break" "kill" "switch" "join" "layout" "resize" "info" "back" "exit")
plugin_menu=("install" "update" "remove" "back" "exit")

if ! type -t fzf; then
    echo "no 'fzf' found!" >&2
    return 1
fi &> /dev/null

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

session_info() {
    local var
    for var in $session_vars; do
        printf "%-30s: %s\n" "$var" "$(tmux display-message -p "#{$var}")"
    done
}

win_info() {
    local var
    for var in $win_vars; do
        printf "%-30s: %s\n" "$var" "$(tmux display-message -p "#{$var}")"
    done
}

pane_info() {
    local var
    for var in $pane_vars; do
        printf "%-30s: %s\n" "$var" "$(tmux display-message -p "#{$var}")"
    done
}

# handle_main [state1] [state2]
handle_main() {
    local ans idx state

    if [[ -n "$1" ]]; then
        state=$1
        shift
        handle_${state} "$@"
        return
    fi

    state="handle_main"
    while :; do
        menu.height 15
        menu.opts "${main_menu[@]}"
        menu.run
        ans=$(menu.ans_opt)
        idx=$(menu.ans_idx)

        if [[ -z "$idx" || -z "$ans" ]]; then
            return 1
        fi

        if [[ "$ans" == "exit" ]]; then
            exit
        fi

        handle_${ans}
    done
}

run_win_cmd() {
    local ans idx state
    local src dst
    local sym opt
    local fzf

    declare -A sym opt
    sym=([swap]="<->"
         [link]="~>"
         [move]="->")
    opt=([break]="break-pane -P"
         [kill]="kill-window"
         [switch]="select-window"
         [rename]="rename-window"
         [new]="new-window -n")

    ans="$1"
    fzf=$(__menu_fzf_tmux)
    case "$ans" in
        rename | new)
            name=$(input_box 'Enter new window title')
            # current window
            tmux ${opt[$ans]} "$name"
            ;;
        swap | move | link)
            src=$(list_win_all | $fzf)
            [[ -z "$src" ]] && return

            dst=$(list_win_all | sed -e "s/^/$src ${sym[$ans]} /" | $fzf | sed -e "s/^$src ${sym[$ans]} //")
            [[ -z "$dst" ]] && return

            src=${src%%-*}
            dst=${dst%%-*}
            tmux ${ans}-window -s $src -t $dst
            ;;
        break | kill | switch)
            src=$(list_win_all | $fzf)
            [[ -z "$src" ]] && return

            src=${src%%-*}
            tmux ${opt[$ans]} -t $src
            ;;
        info)
            win_info | $fzf
            ;;
        exit) return;;
        *) return 1;;
    esac
}

handle_window() {
    local ans idx state op
    local src dst

    if [[ -n "$1" ]]; then
        op=$1
        run_win_cmd $op
        exit
    fi

    state="handle_window"
    menu.height 15
    menu.opts "${win_menu[@]}"
    while :; do
        menu.run
        ans=$(menu.ans_opt)
        idx=$(menu.ans_idx)

        if [[ -z "$ans" ]]; then
            return 1
        fi

        run_win_cmd $ans && exit
    done
}

run_pane_cmd() {
    local ans idx state
    local src dst
    local sym opt

    declare -A sym opt
    sym=([swap]="<->"
         [link]="~>"
         [move]="->")
    opt=([break]="break-pane -P"
         [kill]="kill-window"
         [switch]="select-window"
         [rename]="rename-window"
         [new]="new-window -n")

    ans="$1"
    case "$ans" in
        rename | new)
            name=$(input_box 'Enter new window title')
            # current window
            tmux ${opt[$ans]} "$name"
            ;;
        swap | move | link)
            src=$(list_win_all | fzf)
            [[ -z "$src" ]] && return

            dst=$(list_win_all | sed -e "s/^/$src ${sym[$ans]} /" | fzf | sed -e "s/^$src ${sym[$ans]} //")
            [[ -z "$dst" ]] && return

            src=${src%%-*}
            dst=${dst%%-*}
            tmux ${ans}-window -s $src -t $dst
            ;;
        break | kill | switch)
            src=$(list_win_all | fzf)
            [[ -z "$src" ]] && return

            src=${src%%-*}
            tmux ${opt[$ans]} -t $src
            ;;
        info)
            win_info | fzf
            ;;
        exit) return;;
        *) return 1;;
    esac
}

handle_pane() {
    local ans idx state

    state="handle_pane"
    menu.height 15
    menu.opts "${pane_menu[@]}"
    while :; do
        menu.run
        ans=$(menu.ans_opt)
        idx=$(menu.ans_idx)

        if [[ -z "$idx" ]]; then
            return 1
        fi

        run_pane_cmd $ans && exit
    done
}

run_session_cmd() {
    local ans idx state
    local src dst
    local sym opt

    declare -A sym opt
    sym=([swap]="<->"
         [link]="~>"
         [move]="->")
    opt=([break]="break-pane -P"
         [kill]="kill-window"
         [switch]="select-window"
         [rename]="rename-window"
         [new]="new-window -n")

    ans="$1"
    case "$ans" in
        rename | new)
            name=$(input_box 'Enter new window title')
            # current window
            tmux ${opt[$ans]} "$name"
            ;;
        swap | move | link)
            src=$(list_win_all | fzf)
            [[ -z "$src" ]] && return

            dst=$(list_win_all | sed -e "s/^/$src ${sym[$ans]} /" | fzf | sed -e "s/^$src ${sym[$ans]} //")
            [[ -z "$dst" ]] && return

            src=${src%%-*}
            dst=${dst%%-*}
            tmux ${ans}-window -s $src -t $dst
            ;;
        break | kill | switch)
            src=$(list_win_all | fzf)
            [[ -z "$src" ]] && return

            src=${src%%-*}
            tmux ${opt[$ans]} -t $src
            ;;
        info)
            win_info | fzf
            ;;
        exit) return;;
        *) return 1;;
    esac
}

handle_session() {
    local ans idx state

    state="handle_session"
    while :; do
        menu.height 15
        menu.opts "${session_menu[@]}"
        menu.run
        ans=$(menu.ans_opt)
        idx=$(menu.ans_idx)

        case "$ans" in
            rename)
                name=$(input_box 'Enter new pane title')
                ans=cancel
                tmux select-pane -T "$name" && ans=exit
                ;;
            info)
                ans=cancel
                session_info | fzf
                ans=exit
                ;;
            exit) exit;;
            *|back) return;;
        esac
    done
}

handle_plugin() {
    local ans idx state dir
    dir="${XDG_CONFIG_HOME}/tmux/plugins/tpm/bindings"

    while :; do
        menu.height 15
        menu.opts "${plugin_menu[@]}"
        menu.run
        ans=$(menu.ans_opt)
        idx=$(menu.ans_idx)

        case "$ans" in
            install)
                eval ${dir}/install_plugins
                ;;
            update)
                eval ${dir}/update_plugins
                ;;
            remove)
                eval ${dir}/clean_plugins
                ;;
            exit) exit;;
            *|back) return;;
        esac
    done
}


  # fzf-tmux -p "$1" \
  #   --ansi \
  #   --bind="$2" \
  #   --delimiter=":" \
  #   --layout="$3" \
  #   --no-multi \
  #   --print-query \
  #   --with-nth="3.." \
  #   --color="$4" \
  #   --preview="$CURRENT_DIR/preview.sh $CAPTURE_FILENAME {}" \
  #   --preview-window="$preview_window"
menu.backend "fzf-tmux"
# state='handle_main'
handle_main "$@"
