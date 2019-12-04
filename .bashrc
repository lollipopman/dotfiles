#!/bin/bash
# ~/.bashrc: executed by bash(1) for non-login shells.
# vim: set noexpandtab:shiftwidth=1

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# set umask
umask u=rwx,g=rwx,o=rx

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize
shopt -s cmdhist
shopt -s lithist
# extended globbing, including negating
shopt -s extglob

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
export GOPATH=~/go
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

pathmunge() {
	if ! echo "${PATH}" | grep -Eq "(^|:)$1($|:)"; then
		if [ "$2" = "after" ]; then
			PATH=$PATH:$1
		else
			PATH=$1:$PATH
		fi
	fi
}

pathmunge ~/bin after
pathmunge ~/.cabal/bin
pathmunge ~/go/bin
pathmunge /sbin after
pathmunge /usr/sbin after
pathmunge ~/node_modules/.bin after
pathmunge ~/.cargo/bin

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(lesspipe)"

# set vi mode
set -o vi

# tabs at 4 columns
tabs -4
alias ls='ls -T4 -w80'

alias xclip="xclip -selection clipboard"
alias lsblk='lsblk -o NAME,SIZE,TYPE,FSTYPE,MODEL,MOUNTPOINT,LABEL'
alias addkeys='ssh-add ~/.ssh/id_rsa_git ~/.ssh/id_rsa'
alias htask="task project:home"
alias wtask="task project:work"
alias o="xdg-open"
alias strip-escape-codes='sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"'

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
		printf -v out '\[\e[31m\]\$\[\e[m\]'
	fi
	printf '%s' "${out@P}"
}

corp() {
	ssh -D 8123 -f -C -q -N support01.chi
}

# shellcheck source=.bash-rsi/bashrc
source ~/.bash-rsi/bashrc
source /usr/lib/git-core/git-sh-prompt
PS1='\[\e[36m\e[3m\]\h:\[\e[23m\][\[\e[m\]\w\[\e[36m\]]\[\e[m\]$(__git_ps1 " (%s)")\n\[\e[36m\e[m\]$(dollar $?) '
PS2=' > '
