# .bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

source ~/.aliases

function de {
    CONTAINER=$1
    shift
    CMD="docker exec -it --detach-keys='ctrl-^,q' $CONTAINER env TERM=xterm bash"
    if [ "$#" -gt 0 ]; then
        CMD="$CMD -c '$*'"
    fi
    echo $CMD
    eval $CMD
}

# Copied from https://gist.github.com/jfly/7b94cba17c04d344d62a7bea916bb55a
function start_screen {
    NAME=$1
    shift
    screen -dmS "$NAME" -s bash # start screen

    while test $# -gt 0
    do
        TITLE="$1"
        shift
        CMD="$1"$'\n'
        shift
        screen -S "$NAME" -X title "$TITLE" # set title of window
        screen -S "$NAME" -X stuff "$CMD" # run command in window
        screen -S "$NAME" -X screen # add new window
    done
}

export VISUAL=vim
export EDITOR=vim

if [ -n "$DISPLAY" ]; then
  export BROWSER=chromium
else
  export BROWSER=elinks
fi

if tty -s; then
  green=$(tput setaf 2)
  reset=$(tput sgr0)
fi
MY_BODY="\[$green$bold\]\w\[$reset\] @\h"
END=">"
export PS1="${MY_BODY}${END} "

export PATH=$PATH:$HOME/bin
export PATH=$PATH:$HOME/bin/packer

export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

export PATH=$PATH:$HOME/.gem/ruby/2.4.0/bin
export PATH=$PATH:/usr/local/heroku/bin

export HISTCONTROL=ignorespace

# ctrl-shift-n for vte
[[ -f /etc/profile.d/vte.sh ]] && source /etc/profile.d/vte.sh

# Better dircolors for solarized
# http://archlinux.me/w0ng/2012/04/21/better-dircolors-with-solarized/
eval $(dircolors ~/.dir_colors)

# Lower probability of weird line wrapping issues
# https://wiki.archlinux.org/index.php/bash#Line_wrap_on_window_resize
shopt -s checkwinsize

[[ -f ~/.bashrc_local ]] && source ~/.bashrc_local

# From https://wiki.archlinux.org/index.php/SSH_keys#ssh-agent
if ! pgrep -u $USER ssh-agent > /dev/null; then
  ssh-agent > ~/.ssh-agent-thing
fi
if [[ "$SSH_AGENT_PID" == "" ]]; then
  eval $(<~/.ssh-agent-thing)
fi

# startx at login
[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx
