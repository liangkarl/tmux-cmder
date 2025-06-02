#!/usr/bin/env bash

# basic information
session="$(tmux display-message -p '#S')"
window="$(tmux display-message -p '#W')"
client="$(tmux display-message -p '#{client_name}')"
pane="$(tmux display-message -p '#{pane_id}')"

# finder='fzf-tmux -p 40%,40% -- --reverse'

source menu.bash

main_menu=("clipboard" "keys" "tools" "plugin" "session" "window" "pane")
session_menu=("new" "kill" "switch" "detach" "rename" "info")
win_menu=("swap" "break" "kill" "switch" "move" "rename" "link" "info")
pane_menu=("rename" "swap" "break" "kill" "switch" "join" "layout" "resize" "info")
cb_ans=

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
    local list
    list="
session_activity
session_alerts
session_attached
session_attached_list
session_created
session_format
session_group
session_group_attached
session_group_attached_list
session_group_list
session_group_many_attached
session_group_size
session_grouped
session_id
session_last_attached
session_many_attached
session_marked
session_name
session_path
session_stack
session_windows
    "
    for var in $list; do
        printf "%-30s: %s\n" "$var" "$(tmux display-message -p "#{$var}")"
    done
}

win_info() {
    local list
    list="window_active
window_active_clients
window_active_clients_list
window_active_sessions
window_active_sessions_list
window_activity
window_activity_flag
window_bell_flag
window_bigger
window_cell_height
window_cell_width
window_end_flag
window_flags
window_format
window_height
window_id
window_index
window_last_flag
window_layout
window_linked
window_linked_sessions
window_linked_sessions_list
window_marked_flag
window_name
window_offset_x
window_offset_y
window_panes
window_raw_flags
window_silence_flag
window_stack_index
window_start_flag
window_visible_layout
window_width
window_zoomed_flag
wrap_flag
"
    for var in $list; do
        printf "%-30s: %s\n" "$var" "$(tmux display-message -p "#{$var}")"
    done
}

pane_info() {
    local list
    list="pane_active
pane_at_bottom
pane_at_left
pane_at_right
pane_at_top
pane_bg
pane_bottom
pane_current_command
pane_current_path
pane_dead
pane_dead_signal
pane_dead_status
pane_dead_time
pane_fg
pane_format
pane_height
pane_id
pane_in_mode
pane_index
pane_input_off
pane_last
pane_left
pane_marked
pane_marked_set
pane_mode
pane_path
pane_pid
pane_pipe
pane_right
pane_search_string
pane_start_command
pane_start_path
pane_synchronized
pane_tabs
pane_title
pane_top
pane_tty
pane_unseen_changes
pane_width
    "
    for var in $list; do
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
        menu.add_opt "exit"
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
    menu.add_opt "exit"
    menu.add_opt "back"
    while :; do
        menu.run
        ans=$(menu.ans_opt)
        idx=$(menu.ans_idx)

        if [[ -z "$idx" ]]; then
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
    menu.add_opt "exit"
    menu.add_opt "back"
    while :; do
        menu.run
        ans=$(menu.ans_opt)
        idx=$(menu.ans_idx)

        if [[ -z "$idx" ]]; then
            return 1
        fi

        run_win_cmd $ans && exit
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
        menu.add_opt "exit"
        menu.add_opt "back"
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

menu.backend "fzf"
# state='handle_main'
handle_main "$@"
