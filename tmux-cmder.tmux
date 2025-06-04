#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${CURRENT_DIR}/scripts/util.bash

key="$(tmux_get '@tmux-cmder-bind' '?')"
table="$(tmux_get '@tmux-cmder-table' 'prefix')"

tmux bind-key -N "Open tmux-cmder main menu" -T "$table" "$key" run -b "$CURRENT_DIR/scripts/run.bash";

# @tmux-cmder-root='a'
# @tmux-cmder-key-0='b'
# @tmux-cmder-cmd-0='window'
# @tmux-cmder-msg-0='...'
# @tmux-cmder-key-...
parse_keybind() {
    local keys cmds
    local i key cmd
    keys=()
    cmds=()
	msgs=()
    i=0

    while :; do
        key="$(tmux_get @tmux-cmder-key-$i)"
        if [[ -z "$key" ]]; then
            break
        fi
        keys+="$key"

        cmd="$(tmux_get @tmux-cmder-cmd-$i)"
        if [[ -z "$cmd" ]]; then
            break
        fi
        cmds+="$cmd"

        msg="$(tmux_get @tmux-cmder-msg-$i)"
        if [[ -z "$msg" ]]; then
            break
        fi
        msgs+="$msg"

		tmux bind-key -N "$msg" -T "$table" "$key" run -b "$CURRENT_DIR/scripts/run.bash $cmd"
        i=$((i + 1))
    done
}

parse_keybind
