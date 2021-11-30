#!/bin/bash

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

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
	local exit=$?
	# only display git prompt if current repo is not our dotfiles repo
	if [[ $(git rev-parse --absolute-git-dir 2>/dev/null) != ~/.git ]]; then
		__git_ps1 "${@}"
	fi
	return $exit
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
export LESS="-fMiRx4"
export EDITOR=vi
export LIBVIRT_DEFAULT_URI='qemu:///system'
export RMADISON_ARCHITECTURE='amd64'
export DEBEMAIL="hathaway@paypal.com"
export DEBFULLNAME="Jesse Hathaway"
export MANWIDTH=80
# allows less to know the total line length via stdin, by going to the EOF,
# this then allows it to generate a percentage in the status line.
export MANPAGER='less +Gg'
# don't put duplicate lines in the history. See bash(1) for more options
export HISTCONTROL=erasedups
export HISTFILESIZE=2000

# Go
export GOPATH=~/go
pathmunge ~/go/bin

# Java
JAVA_HOME=$(readlink -f /usr/bin/java | sed 's:bin/java::')
export JAVA_HOME

# Firefox, scale the UI!
export GDK_DPI_SCALE=1.5

# CDPATH for common directories
CDPATH=.:~:~/src:~/bt:"${GOPATH}"/src/github.braintreeps.com/lollipopman

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
# cpair
pathmunge /home/admin/bt/dotfiles/bin
pathmunge /home/admin/cosmos/cpair-tools/bin

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
alias htask="task +home"
alias wtask="task +braintree"
alias o="xdg-open"
alias ls='ls -T4 -w80 -p'

if [[ -v CPAIR ]]; then
	if [[ $USER == 'admin' ]]; then
		export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"
	fi
fi

function strip-escape-codes {
	sed -E 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g'
}

function oneliner() {
	sed -E -e 's/#.*$//' -e '/^\s*$/d' -e 's/$/;/' -e 's/\s+/ /g' -e 's/(then|else|\{);/\1/g' | paste -s -d' '
}

# cpair
fixssh() {
	eval $(~/bt/system-scripts/bin/fixssh $1 $2)
}

# secrets vault
sts() {
	cd ~/src/secrets-vault || return 1
	bash bin/get-sts-credentials-for-blue -a production -u jhathaway
}

# pandoc
xclipmd() {
	pandoc -f gfm -t html --self-contained "$1" | xclip -t text/html
}

export GIT_PS1_SHOWCOLORHINTS=1
export GIT_PS1_SHOWDIRTYSTATE=1
PS1='\[\e[36m\e[3m\]\h:\[\e[23m\][\[\e[m\]\w\[\e[36m\]]\[\e[m\]$(git_ps1 " (%s)")\n\[\e[36m\e[m\]$(dollar $?) '
PS2=' > '
