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
alias supercopy="rsync -avh --progress --fsync"
# Mirror DATALAKE_2026 to both ybox drives (with --delete). `susssync -n` previews.
# Checks each drive is mounted, syncs both even if one fails, ends with a verdict.
# --no-perms/owner/group: exFAT/NTFS can't store them, so rsync would report spurious diffs.
susssync() {
	local src="/home/ysussman/Desktop/DATALAKE_2026/" rc=0 box mnt dest
	for box in ybox2 ybox3; do
		# Find the drive by filesystem label, wherever it's mounted (/media or /run/media).
		if ! mnt=$(findmnt -no TARGET -S "LABEL=$box"); then
			echo "✗ $box: not mounted, skipped" >&2; rc=1; continue
		fi
		dest="$mnt/ybox_backup/backup_sussworld/DATALAKE_2026/"
		if rsync -rlt --no-perms --no-owner --no-group --modify-window=1 --delete --itemize-changes --info=stats1 "$@" "$src" "$dest"; then
			echo "✓ $box: $([[ " $* " == *" -n "* ]] && echo previewed || echo synced) $(date +%H:%M)"
		else
			echo "✗ $box: rsync failed (exit $?)" >&2; rc=1
		fi
	done
	return $rc
}

alias au="sudo apt update"
alias alu="sudo apt list --upgradable"
alias afu="sudo apt full-upgrade"
alias apc="sudo apt autopurge && sudo apt autoclean"
# alias badsnap='sudo snap-store --quit && sudo snap refresh snap-store && sudo snap refresh'

alias gs="git status"
alias glo="git log --oneline"
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

# Git worktrees
alias gwl="git worktree list"
alias gwr="git worktree remove"
# gwt-add <branch> [base] — create worktree in ../repo-branch/ and cd into it
gwt() {
  local branch="$1" base="${2:-HEAD}"
  if [ -z "$branch" ]; then
    echo "Usage: gwt <branch-name> [base-ref]"
    return 1
  fi
  local repo_name
  repo_name=$(basename "$(git rev-parse --show-toplevel)")
  local wt_dir="../${repo_name}-${branch}"
  git worktree add -b "$branch" "$wt_dir" "$base" && cd "$wt_dir"
}
# gwt-go <branch> — cd into an existing worktree
gwt-go() {
  local branch="$1"
  if [ -z "$branch" ]; then
    echo "Usage: gwt-go <branch-name>"
    return 1
  fi
  local wt_path
  wt_path=$(git worktree list --porcelain | grep -B2 "branch refs/heads/$branch" | grep "^worktree " | sed 's/^worktree //')
  if [ -z "$wt_path" ]; then
    echo "No worktree found for branch '$branch'"
    return 1
  fi
  cd "$wt_path"
}

alias ga="git add -A && gs"
alias gcam="git add -A && git commit -m"

# To add specific styling for e.g. linebreaks/padding/etc:
# convert md to html, then open in browser, modify CSS, and print as pdf
alias htmlify='function _convert_to_html() { pandoc "$1" -f markdown -t html -s -o "${1%.*}.html"; };_convert_to_html'

alias wtpserve="cd ~/Desktop/wtp && mix phx.server"
alias wtpbackup='DEST="/home/ysussman/Desktop/yr_workspace/40 Paper Trail - 2026"; TS=$(date -u +%Y-%m-%dT%H%M%S); rm -rf "$DEST"/wtp_backup--*; mkdir -p "$DEST/wtp_backup--$TS" && cd ~/Desktop/wtp && ./scripts/backup.exs "$DEST/wtp_backup--$TS"'   

alias hzaserve="cd ~/Desktop/hanzi-expand/ && .venv/bin/hanzi-expand serve"

alias c="claude"

# Paper Trail SSG: rebuild the blog locally (drafts included, for the trial period)
# alias ptwrebuild='(cd "/home/ysussman/Desktop/yr_workspace/40 Paper Trail - 2026/blog_plans/ssg_pipeline" && mise exec -- ./build.sh --include-drafts)'
# Paper Trail SSG: live local dev — watch-rebuild in the background, serve in the foreground (Ctrl-C stops both)
# alias ptwserve='(cd "/home/ysussman/Desktop/yr_workspace/40 Paper Trail - 2026/blog_plans/ssg_pipeline" && { mise exec -- ./build.sh --include-drafts --watch & } && trap "kill %1 2>/dev/null" EXIT && ./serve.sh)'
# alias rss="mise exec bun -- bun run ~/Desktop/rss-reader/src/index.ts"                                  

# --- startupservices ---------------------------------------------------
# _svcpayload <tab-label> <alias-or-command>  ->  the -e payload for one tab.
# bash -ic re-sources this .bashrc, so the aliases above stay the single
# source of truth; `exec bash` keeps the tab alive if the service dies.
_svcpayload() {
    printf "bash -ic '%s; ec=\$?; echo; echo \"[%s exited rc=\$ec]\"; exec bash'" "$2" "$1"
}

# two tabs in one window (hzaserve no longer starts at login; run it by hand).
# Talon is X11-only and crashes under Wayland, so its tab only opens in an
# X11 session; under GNOME/Wayland you just get the wtp tab.
startupservices() {
    if [ "${XDG_SESSION_TYPE:-}" = x11 ]; then
        gnome-terminal --geometry=110x30 \
            --window -t talon -e "$(_svcpayload talon tln)" \
            --tab    -t wtp   -e "$(_svcpayload wtp   wtpserve)" 2>/dev/null
    else
        gnome-terminal --geometry=110x30 \
            --window -t wtp   -e "$(_svcpayload wtp   wtpserve)" 2>/dev/null
    fi
}

# two separate windows (the original, minus hanzi)
_svcwin() {
    gnome-terminal --title="$1" --geometry="$2" -- \
        bash -ic "$3; printf '\n[%s exited (rc=%s)]\n' '$1' \"\$?\"; exec bash"
}
startupwindows() {
    _svcwin talon '100x20+0+0'     tln
    _svcwin wtp   '100x24+0+430'   wtpserve
}
