#!/bin/bash

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Get our secrets, 🤐
# shellcheck source=.env_secrets
source ~/.env_secrets
# shellcheck source=.bash-rsi/bashrc
source ~/.bash-rsi/bashrc
if [[ -e /usr/lib/git-core/git-sh-prompt ]]; then
	source /usr/lib/git-core/git-sh-prompt
fi

pathmunge() {
	if ! echo "${PATH}" | grep -Eq "(^|:)$1($|:)"; then
		if [ "$2" = "after" ]; then
			PATH=$PATH:$1
		else
			PATH=$1:$PATH
		fi
	fi
}

# https://unix.stackexchange.com/questions/18087/can-i-get-individual-man-pages-for-the-bash-builtin-commands
man() {
	local cur_width

	cur_width=$(tput cols)

	if [[ $cur_width -gt $MANWIDTH ]]; then
		cur_width=$MANWIDTH
	fi

	if [[ "${#@}" -gt 1 ]]; then
		MANWIDTH="${cur_width}" command -p man "$@"
	else
		case "$(type -t "$1"):$1" in
		builtin:*)
			help "$1" | "${PAGER:-less}" # built-in
			;;
		*[[?*]*)
			help "$1" | "${PAGER:-less}" # pattern
			;;
		*)
			MANWIDTH="${cur_width}" command -p man "$@" # something else, presumed to be an external command
			;;
		esac
	fi
}

fe() {
	local files
	mapfile -t files <(fzf-tmux --query="$1" --multi --select-1 --exit-0)
	if [[ "${#files[@]}" -gt 0 ]]; then
		${EDITOR:-vim} "${files[@]}"
	fi
}

dollar() {
	local rc
	local out

	rc=$1
	if [[ $rc -eq 0 ]]; then
		printf -v out '\[\e[36m\]\$\[\e[m\]'
	else
		printf -v out '\[\e[1;31m\]\$\[\e[m\]'
	fi
	printf '%s' "${out@P}"
}

corp() {
	ssh -D 8123 -f -C -q -N support01.chi
}

git_ps1() {
	# preserve exit status for other other PS1 functions
	local exit_status=$?
	# only display git prompt if current repo is not our dotfiles repo
	if [[ $(git rev-parse --absolute-git-dir 2>/dev/null) != ~/.git ]]; then
		__git_ps1 "${@}"
	fi
	return $exit_status
}

# set umask
umask u=rwx,g=rwx,o=rx

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize
shopt -s cmdhist
shopt -s lithist
# extended globbing, including negating
shopt -s extglob
shopt -s globstar
# List outstanding jobs rather than exiting
shopt -s checkjobs

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

# Exports
export HISTIGNORE="&:ls:[bf]g:exit"
export LESS='--LONG-PROMPT --ignore-case --tabs=4 --RAW-CONTROL-CHARS --mouse'
export EDITOR=vi
export LIBVIRT_DEFAULT_URI='qemu:///system'
export RMADISON_ARCHITECTURE='amd64'
export DEBFULLNAME='Jesse Hathaway'
export DEBEMAIL='jesse@mbuki-mvuki.org'
# Makes manual pages more readable
export MANWIDTH=80
# Allows less to know the total line length via stdin, by going to the EOF,
# this then allows it to generate a percentage in the status line.
export MANPAGER='less +Gg'
# Don't put duplicate lines in the history. See bash(1) for more options
export HISTCONTROL=erasedups
export HISTFILESIZE=2000
export DOCKER_HOST="unix:///run/user/${UID}/podman/podman.sock"

# Go
export GOPATH=~/go
pathmunge ~/go/bin

# Java
JAVA_HOME=$(readlink -f /usr/bin/java | sed 's:bin/java::')
export JAVA_HOME

# Firefox, scale the UI!
export GDK_DPI_SCALE=1.5
# VLC
export QT_SCALE_FACTOR=1.5

# CDPATH for common directories
CDPATH=.:~:~/src:

# add sbin
pathmunge /sbin after
pathmunge /usr/sbin after
# personal scripts
pathmunge ~/bin after
# haskell
pathmunge ~/.cabal/bin
# nodejs
pathmunge ~/node_modules/.bin after
# rust
pathmunge ~/.cargo/bin after

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(lesspipe)"

# set vi mode
set -o vi

# Read html from a pipe and display it in chrome
function chromepipe() {
	shopt -s lastpipe
	base64 -w0 | read -r data
	chrome -p -- --new-window 'data:text/html;base64,'"${data}"
}

# tabs at 4 columns
tabs -4

# Aliases
alias xclip="xclip -selection clipboard"
alias lsblk='lsblk -o NAME,SIZE,TYPE,FSTYPE,MODEL,MOUNTPOINT,LABEL'
alias o="xdg-open"
alias ls='ls -T4 -w80 -p'

function strip-escape-codes {
	sed -E 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g'
}

function oneliner() {
	sed -E -e 's/#.*$//' -e '/^\s*$/d' -e 's/$/;/' -e 's/\s+/ /g' -e 's/(then|else|\{);/\1/g' | paste -s -d' '
}

function ncdu() {
	NO_COLOR=true command ncdu "$@"
}

# pandoc
xclipmd() {
	pandoc -f gfm -t html --self-contained "$1" | xclip -t text/html
}

function clock() {
	TZ=US/Pacific date \
		'+San Francisco : %R'
	TZ=America/Chicago date \
		'+Chicago       : %R'
	TZ=US/Eastern date \
		'+New York      : %R'
	TZ=Europe/Madrid date \
		'+Madrid        : %R'
	TZ=Etc/UTC date \
		'+UTC           : %R'
}

# beep when you read a line from input
function line-beeper {
	while IFS= read -r line; do
		printf '%s\a\n' "$line"
	done
}

function wmif-weekly-meeting {
	printf '## Etherpad\n'
	printf -- '- <https://etherpad.wikimedia.org/p/SRE-Foundations-%s>\n' "$(date -I)"
	printf '\n## Completed Tasks\n'
	task context work >/dev/null
	task end.after:today-1wk completed
	printf '\n## Git Commits\n'
	PAGER='' git -C ~/src/wmf/puppet log --oneline --since=1.weeks --author=jhathaway@wikimedia.org
}

# e.g. https://gerrit.wikimedia.org/r/plugins/gitiles/operations/puppet/+/feee1540547412d9bc4429df570a3c6da151162e
function gerrit-link {
	commit=$1
	origin_url=$(git remote get-url origin)
	gerrit_base='https://gerrit.wikimedia.org/r/'
	gitiles='https://gerrit.wikimedia.org/r/plugins/gitiles'
	repo_path=${origin_url#"$gerrit_base"}
	printf '%s/%s/+/%s\n' "$gitiles" "$repo_path" "$commit"
}

export GIT_PS1_SHOWCOLORHINTS=1
export GIT_PS1_SHOWDIRTYSTATE=1
PS1='\[\e[36m\e[3m\]\h:\[\e[23m\][\[\e[m\]\w\[\e[36m\]]\[\e[m\]$(git_ps1 " (%s)")\n\[\e[36m\e[m\]$(dollar $?) '
PS2=' > '
