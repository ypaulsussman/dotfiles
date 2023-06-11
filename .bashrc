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

## NB All lines commented with two octothorpes =>
## "not by-default to-be-implemented on this machine" 
# (due to uncertainty of runtime-management strategy,
## i.e. containerization vs nvm/rvm/pyenv/etc vs different languages)

# ====== ruby ====== #

# NB you used the script at 
# https://github.com/rbenv/rbenv-installer#rbenv-installer
# (not the version available via apt)
## export PATH=$PATH:/home/ysuss/.rbenv/bin
## eval "$(rbenv init -)"

# ====== pyenv ====== #
## export PYENV_ROOT="$HOME/.pyenv"
## export PATH="$PYENV_ROOT/bin:$PATH"
## eval "$(pyenv virtualenv-init -)"
## if command -v pyenv 1>/dev/null 2>&1; then
##  eval "$(pyenv init --path)"
## fi

# ====== nvm ====== #

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# ====== fly.io ====== #
## export FLYCTL_INSTALL="/home/y/.fly"
## export PATH="$FLYCTL_INSTALL/bin:$PATH"

# ====== Shortcuts ====== #

alias coba="code ~/.bashrc"
alias soba="source ~/.bashrc"

alias gs="git status"
alias gb="git branch"
alias gc="git checkout"
alias gcb="git checkout -b"
alias gcd="git checkout development"
alias gcm="git checkout master"
alias gbd="git branch -d"
alias grsh="git reset --hard"

alias gst="git stash"
alias gsl="git stash list"
alias gsd="git stash drop"
alias gsa="git stash apply"

alias gf="git fetch"
alias gp="git pull"
alias ga="git add -A && gs"
alias gcam="git add -A && git commit -m"
alias grbi="git rebase -i"

alias nrs="npm run start"
alias nrd="npm run dev"
alias nrt="npm run test"
alias nrb="npm run build"

## alias yi="yarn install"
## alias yrs="yarn run start"
## alias yrt="yarn run test"
## alias yrb="yarn run build"

## alias bi="bundle install"
## alias fs="foreman start"
## alias gphm="git push heroku master"

alias ankify="ruby ~/Desktop/convenience_scripts/ruby_scripts/ankify_markdown.rb ~/Desktop/anki_whiteboard.md && code ~/Desktop/anki_whiteboard.html"

alias gsm='gnome-system-monitor'
alias tln='~/talon/run.sh'
alias fsnap='sudo pkill snap-store && sudo snap refresh snap-store'

