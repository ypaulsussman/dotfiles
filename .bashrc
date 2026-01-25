# ================================================================
# UBUNTU DEFAULTS
# ================================================================

# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# USER UPDATE:
# your preferred PS1 prompt
PS1='${debian_chroot:+($debian_chroot)}\W \$ '

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# ================================================================
# USER ADDITIONS
# ================================================================

# Activate mise environment if available
eval "$(~/.local/bin/mise activate bash)"

# Shortcuts

alias coba="code ~/.bashrc"
alias soba="source ~/.bashrc"

alias tln='~/talon/run.sh'
alias copy="rsync -avh --progress"
alias susssync='rsync -av --delete --progress "/home/ysussman/Desktop/40 Paper Trail - 2026/" "/media/ysussman/ybox2/ybox_backup/backup_sussworld/40 Paper Trail - 2026/" && rsync -av --delete --progress "/home/ysussman/Desktop/40 Paper Trail - 2026/" "/media/ysussman/ybox3/ybox_backup/backup_sussworld/40 Paper Trail - 2026/"'

alias au="sudo apt update"
alias alu="sudo apt list --upgradable"
alias afu="sudo apt full-upgrade"
alias apc="sudo apt autopurge && sudo apt autoclean"
# alias badsnap='sudo snap-store --quit && sudo snap refresh snap-store && sudo snap refresh'

alias gs="git status"
alias gb="git branch"
alias gc="git checkout"
alias gcb="git checkout -b"
alias gcm="git checkout master"
alias gbd="git branch -d"
alias gf="git fetch"
alias gp="git pull"
alias gpom="git push origin master"

alias grsh="git reset --hard"
alias grbi="git rebase -i"

alias gst="git stash"
alias gsl="git stash list"
alias gsd="git stash drop"
alias gsa="git stash apply"

alias ga="git add -A && gs"
alias gcam="git add -A && git commit -m"

# To add specific styling for e.g. linebreaks/padding/etc:
# convert md to html, then open in browser, modify CSS, and print as pdf
alias htmlify='function _convert_to_html() { pandoc "$1" -f markdown -t html -s -o "${1%.*}.html"; };_convert_to_html'

alias wtpserve="cd ~/Desktop/wtp && mix phx.server"
alias wtpbackup='DEST="/home/ysussman/Desktop/yr_workspace/40 Paper Trail - 2026"; TS=$(date -u +%Y-%m-%dT%H%M%S); rm -rf "$DEST"/wtp_backup--*; mkdir -p "$DEST/wtp_backup--$TS" && cd ~/Desktop/wtp && ./scripts/backup.exs "$DEST/wtp_backup--$TS"'   

alias c="claude"
