ZSH_ROOT=$(dirname $0)

# History

SAVEHIST=100000
HISTSIZE=100000
HISTFILE=${ZSH_ROOT}/history
setopt inc_append_history
setopt histignoredups
setopt histignorespace
setopt extended_history
setopt share_history
setopt hist_verify

# Aliases

alias -s c=vim

alias mv='mv -v'
alias cdl='cd ~/var/downloads'
alias clr='clear'
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
alias gglc='gilc ~/dev | grep '
alias gil='git log'
alias gifa='git last'
alias gin='git next'
alias giri='git rebI'
alias gifre='gif && gire'
alias gire='git reb'
alias gir='tig refs'
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

bindkey '^R' history-incremental-pattern-search-backward
bindkey '^S' history-incremental-pattern-search-forward

# Prompt

# (took stuff from https://github.com/Parth/dotfiles)

autoload -U colors && colors

setopt PROMPT_SUBST

set_prompt() {
    local LAST_EXIT_CODE=$?
    # [
    PS1="%{$fg_bold[white]%}[%{$reset_color%}"

    # Time

    local dh=`print -n "%{\033[1;38;2;0;127;127m%}"`
    PS1+="${dh}%D{%H:%M}%{$reset_color%}"

    # Status Code
    if [[ $LAST_EXIT_CODE == "0" ]] ; then
	PS1+=" %{$fg_bold[green]%}<%{$reset_color$fg[green]%}00%{$fg_bold[green]%}>%{$reset_color%}"
    else
	PS1+=" %{$fg_bold[red]%}<%{$reset_color$fg[red]%}${(l:2::0:)$(( [##16] $?))}%{$fg_bold[red]%}>%{$reset_color%}"
    fi

    # Git status
    if git rev-parse --is-inside-work-tree 2> /dev/null | grep -q 'true' ; then
	PS1+=' '
	PS1+="%{$fg_bold[cyan]%}<%{$reset_color$fg[cyan]%}$(git rev-parse --abbrev-ref HEAD)%{$reset_color%}"
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
    fi

    # PID
    if [[ $! -ne 0 ]]; then
	PS1+=' '
	PS1+="%{$fg[yellow]%}PID:$!%{$reset_color%}"
    fi

    # Sudo: https://superuser.com/questions/195781/sudo-is-there-a-command-to-check-if-i-have-sudo-and-or-how-much-time-is-left
    CAN_I_RUN_SUDO=$(sudo -n uptime 2>&1|grep "load"|wc -l)
    if [ ${CAN_I_RUN_SUDO} -gt 0 ]
    then
	PS1+=' '
	PS1+="%{$fg_bold[red]%}SUDO%{$reset_color%}"
    fi

    # Path: http://stevelosh.com/blog/2010/02/my-extravagant-zsh-prompt/

    local pwd=${PWD/#$HOME\//}
    local dirpwd=$(dirname ${pwd})
    if [[ "$dirpwd" == "." ]] ;then
	dirpwd=""
    else
	dirpwd="$dirpwd/"
    fi
    PS1+=" %{$fg_bold[magenta]%}%M%{$reset_color$fg[white]%}:${dirpwd}%{$fg_bold[white]%}$(basename ${pwd})%{$reset_color%}"

    # End

    PS1+="%{$fg_bold[white]%}]%{$reset_color%}$ "
}

precmd_functions+=set_prompt

preexec () {
    (( ${#_elapsed[@]} > 1000 )) && _elapsed=(${_elapsed[@]: -1000})
    _start=$SECONDS
}

precmd () {
    (( _start >= 0 )) && _elapsed+=($(( SECONDS-_start )))
    _start=-1
}

function reload() {
    exec zsh
}
