ZSH_ROOT=$(dirname $0)

# History

SAVEHIST=100000
HISTSIZE=100000
HISTFILE=${ZSH_ROOT}/history

# Aliases

alias -s c=vim

alias g='git'
alias mv='mv -v'
alias cdl='cd ~/var/downloads'
alias clr='clear'
alias gcam='g Cam'
alias gifme='git fetch da-x'
alias gih='git show'
alias gis='git status'
alias gipc='git pushc'
alias gic='git co'
alias gid='git diff'
alias gif='git fetch'
alias gibr='git branch -D'
alias gib='git branch -v'
alias gilc='git list-clones'
alias gig='git grep'
alias gil='git log'
alias gifa='git last'
alias gin='git next'
alias giri='git rebI'
alias gifre='gif && gire'
alias gire='git reb'
alias gir='tig refs'
alias gam='git amend'
alias gamd='git amendNDA'
alias gre='grep'
alias godo='git todo'
alias a='cat ${ZSH_ROOT}/zshrc.sh | grep ^alias | sort'
alias v='vim -p'
alias h='cd ~'

# Typos

alias gerp='grep'
alias rload='reload'
alias rloa='reload'
alias dc='cd'
alias dmseg='dmesg'

# Env

EDITOR="vim"
VISUAL="vim"
GREP_COLORS='ms=38;5;47;1:mc=01;34:sl=:cx=:fn=38;5;117:ln=38;5;32:bn=31:se=38;5;50;1'
LESSOPEN="|fancydiff file %s -e"

# Terminal setup

stty -ixon
stty stop undef
stty start undef

bindkey "^[[5;30001~" accept-line
bindkey "^[[5;30002~" accept-line
bindkey "^[[5;30003~" accept-line
bindkey "^[[5;30005~" accept-line

my-noop-func() {}
zle -N my-noop-func

bindkey "^[[5;30014~" my-noop-func
bindkey "^[[1;3A" my-noop-func
bindkey "^[[1;3B" my-noop-func
bindkey "^[[1;3C" my-noop-func
bindkey "^[[1;3D" my-noop-func
bindkey "^[[11;5~" my-noop-func
bindkey "^[[12;5~" my-noop-func
bindkey "^[[13;5~" my-noop-func
bindkey "^[[14;5~" my-noop-func
bindkey "^[[11;3~" my-noop-func
bindkey "^[[12;3~" my-noop-func
bindkey "^[[13;3~" my-noop-func
bindkey "^[[14;3~" my-noop-func
bindkey "^[[11;6~" my-noop-func
bindkey "^[[12;6~" my-noop-func
bindkey "^[[13;6~" my-noop-func
bindkey "^[[14;6~" my-noop-func

bindkey "^[[2;5~" my-noop-func
bindkey "^[[3;5~" my-noop-func
bindkey "^[[7;5~" my-noop-func
bindkey "^[[8;5~" my-noop-func
bindkey "^[[5;5~" my-noop-func
bindkey "^[[6;5~" my-noop-func

# Autoload stuff

autoload -U compaudit compinit
autoload -U colors && colors

# Other options

setopt auto_cd
setopt multios

# External stuff

DISABLE_AUTO_UPDATE=true

plugins=()
ZSH=${ZSH_ROOT}/oh-my-zsh
source ${ZSH_ROOT}/oh-my-zsh/oh-my-zsh.sh
# source ${ZSH_ROOT}/oh-my-zsh/lib/history.zsh
# source ${ZSH_ROOT}/oh-my-zsh/lib/key-bindings.zsh
# source ${ZSH_ROOT}/oh-my-zsh/lib/completion.zsh
source ${ZSH_ROOT}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

unset DISABLE_AUTO_UPDATE

# History, part #2

setopt no_inc_append_history
setopt histignoredups
setopt histignorespace
setopt extended_history
setopt share_history
setopt hist_verify

up-line-or-local-history() {
    zle set-local-history 1
    zle up-line-or-history
    zle set-local-history 0
}
zle -N up-line-or-local-history
down-line-or-local-history() {
    zle set-local-history 1
    zle down-line-or-history
    zle set-local-history 0
}
zle -N down-line-or-local-history

bindkey '^R' history-incremental-pattern-search-backward
bindkey '^F' history-incremental-pattern-search-forward
bindkey "^[[A" up-line-or-local-history
bindkey "^[[B" down-line-or-local-history
bindkey "^[[1;5A" up-line-or-history
bindkey "^[[1;5B" down-line-or-history

# Command line editing shortcuts for Git

emit-current-git-hash() {
    local s="$(git rev-parse HEAD)"

    # Append 's' as if it was written manually, advancing the cursor
    BUFFER="${BUFFER[1,$(($CURSOR))]}$s${BUFFER[$(($CURSOR + 1)),100000]}"
    CURSOR=$(($CURSOR + $#s))
}
zle -N emit-current-git-hash

emit-current-git-branch-name() {
    BUFFER+="$(git rev-parse --abbrev-ref HEAD)"
}
zle -N emit-current-git-branch-name

emit-current-git-path-to-root() {
    local s="$(git rev-parse --show-cdup)"

    # Append 's' as if it was written manually, advancing the cursor
    BUFFER="${BUFFER[1,$(($CURSOR))]}$s${BUFFER[$(($CURSOR + 1)),100000]}"
    CURSOR=$(($CURSOR + $#s))
}
zle -N emit-current-git-path-to-root

emit-current-git-root-relative() {
    local s="$(git rev-parse --show-prefix)"

    # Append 's' as if it was written manually, advancing the cursor
    BUFFER="${BUFFER[1,$(($CURSOR))]}$s${BUFFER[$(($CURSOR + 1)),100000]}"
    CURSOR=$(($CURSOR + $#s))
}
zle -N emit-current-git-root-relative

bindkey "^[gb" emit-current-git-branch-name
bindkey "^[gh" emit-current-git-hash
bindkey "^[gr" emit-current-git-path-to-root
bindkey "^[gd" emit-current-git-root-relative

# Prompt

# (took stuff from https://github.com/Parth/dotfiles)

autoload -U colors && colors

HOST_NAME_PROMPT_OVERRIDE=$(hostname)
HOST_PC_PROMPT_COLOR="$fg_bold[magenta]"

if [[ -e ${ZSH_ROOT}/per-host-config.zsh ]] ; then
    source ${ZSH_ROOT}/per-host-config.zsh
fi

setopt PROMPT_SUBST

# From: https://github.com/trapd00r/Documentation/blob/master/zsh/zshrc_mikachu

autoload -U narrow-to-region
function _narrow_to_region_marked()
{
    local right
    local left
    local OLDMARK=MARK
    local wasregion=1
    if ((REGION_ACTIVE == 0)); then
	MARK=CURSOR
	wasregion=0
    fi
    REGION_ACTIVE=0
    if ((MARK < CURSOR)); then
	left="$LBUFFER[0,$((MARK-CURSOR-1))]"
	right="$RBUFFER"
    else
	left="$LBUFFER"
	right="$BUFFER[$((MARK+1)),-1]"
    fi
    narrow-to-region -p "$left>>|" -P "|<<$right" "$@"
    MARK=OLDMARK
    if ((wasregion)); then
	REGION_ACTIVE=1
    fi
}
zle -N _narrow_to_region_marked
bindkey "^X"    _narrow_to_region_marked

LAST_EXIT_STATUS_COLLECTED=0

set_prompt() {
    local LAST_EXIT_CODE=$?
    local dh=`print -n "%{\033[1;38;2;0;127;127m%}"`
    local gh2=`print -n "\033[38;2;110;110;110m"`

    # Status Code
    if [[ $LAST_EXIT_CODE != "0" ]] ; then
	if [[ $LAST_EXIT_STATUS_COLLECTED != "1" ]] ; then
	    echo
	    echo "$gh2"\["${fg[white]}\$? -> $reset_color$fg[red]${(l:2::0:)$(( [##16] $LAST_EXIT_CODE))}$gh2"\]
	fi
	LAST_EXIT_STATUS_COLLECTED=1
    fi

    # [
    PS1="%{$gh2%}[ %{$reset_color%}"

    # Time

    PS1+="${dh}%D{%H:%M}%{$reset_color%}"

    # Git status
    if git rev-parse --is-inside-work-tree 2> /dev/null | grep -q 'true' ; then
	PS1+=' '
	PS1+="%{$fg_bold[cyan]%}<%{$reset_color$fg[cyan]%}$(git rev-parse --abbrev-ref HEAD 2>/dev/null)%{$reset_color%}"
	if [ "$(git config core.prompt-disable)" != "true" ] ; then
	    if [ $(git status --short | wc -l) -gt 0 ]; then
		PS1+="%{$fg[red]%}+$(git status --short | wc -l | awk '{$1=$1};1')%{$reset_color%}"
	    fi
	fi
	PS1+="%{$fg_bold[cyan]%}>%{$reset_color$fg[cyan]%}"
    fi

    # Timer: http://stackoverflow.com/questions/2704635/is-there-a-way-to-find-the-running-time-of-the-last-executed-command-in-the-shel
    if [[ $_elapsed[-1] -ne 0 ]]; then
	PS1+=' '
	PS1+="%{$fg[magenta]%}$_elapsed[-1]%{$reset_color%}"
	_elapsed=(0)
    fi

    # PID
    if [[ $! -ne 0 ]]; then
	PS1+=' '
	PS1+="%{$fg[yellow]%}PID:$!%{$reset_color%}"
    fi

    # Sudo: https://superuser.com/questions/195781/sudo-is-there-a-command-to-check-if-i-have-sudo-and-or-how-much-time-is-left

    if [[ "$NO_SUDO_PROMPT_CHECK" == "y" ]] ;then
	CAN_I_RUN_SUDO=$(sudo -n uptime 2>&1|grep "load"|wc -l)
	if [ ${CAN_I_RUN_SUDO} -gt 0 ]
	then
	    PS1+=' '
	    PS1+="%{$fg_bold[red]%}SUDO%{$reset_color%}"
	fi
    fi

    # Path: http://stevelosh.com/blog/2010/02/my-extravagant-zsh-prompt/

    local pwd="${PWD/#$HOME\//}"
    local dirpwd="${pwd:h}"
    local basepwd="${pwd:t}"
    if [[ "$pwd" == "/" ]] && [[ "$basepwd" == "/" ]]  ;then
	basepwd="/"
	dirpwd=""
    elif [[ "$dirpwd" == "/" ]] && [[ "$basepwd" != "/" ]]  ;then
	dirpwd="/"
    elif [[ "$dirpwd" == "." ]] ;then
	dirpwd=""
    elif [[ "$pwd" == "$HOME" ]] ;then
	dirpwd=""
	basepwd=""
    else
	dirpwd="$dirpwd/"
    fi
    PS1+=" %{${HOST_PC_PROMPT_COLOR}%}${HOST_NAME_PROMPT_OVERRIDE}%{$reset_color$fg[white]%}:${dirpwd}%{$fg_bold[white]%}${basepwd}%{$reset_color%}"

    # End

    PS1+="%{$gh2%} ]%{$fg_bold[white]%}\$%{${reset_color}%} "
}

precmd_functions+=set_prompt

preexec () {
    LAST_EXIT_STATUS_COLLECTED=0
    (( ${#_elapsed[@]} > 1000 )) && _elapsed=(${_elapsed[@]: -1000})
    _start=$SECONDS
}

precmd () {
    (( _start >= 0 )) && _elapsed+=($(( SECONDS-_start )))
    _start=-1
}

reload () {
    exec zsh
}

dotfiles () {
    case $1 in
	sync)
            cd ~/.files
            ./sync.sh
            cd -
	    ;;
	*)
	    echo "Unknown command $1"
	    ;;
    esac
}

function cd-to-backlink() {
    $(python ${ZSH_ROOT}/backlink.py)
}

cd-to-backlink

