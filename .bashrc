# ====== Ubuntu ~Defaults ====== #

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth
# append to the history file, don't overwrite it
shopt -s histappend

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
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# ====== nvm ====== #

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# ====== Silliness ====== #

# make your %-delineated file
# $ strfile -c % taoup_quotes taoup_quotes.dat
# move both files to /usr/share/games/fortunes
alias wugui="fortune taoup_quotes | cowsay -f turtle"

# ====== Shortcuts ====== #

alias coba="code ~/.bashrc"
alias soba="source ~/.bashrc"

alias gs="git status"
alias gb="git branch"
alias gc="git checkout"
alias gcb="git checkout -b"
alias gcm="git checkout master"
alias gf="git fetch"
alias gp="git pull"
alias grsh="git reset --hard"
alias grbi="git rebase -i"

alias gst="git stash"
alias gsl="git stash list"
alias gsd="git stash drop"
alias gsa="git stash apply"

alias ga="git add . && gs"
alias gcam="git commit -am"

alias nrs="npm run start"
alias nrt="npm run test"
alias nrb="npm run build"
alias yi="yarn install"
alias yrs="yarn run start"
alias yrt="yarn run test"
alias yrb="yarn run build"
