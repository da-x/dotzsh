ZSH_ROOT=$(dirname $0)

# Oh-my-zsh and plugins activation

plugins=()
ZSH=${ZSH_ROOT}/oh-my-zsh
DISABLE_AUTO_UPDATE=true
CASE_SENSITIVE=true
source ${ZSH_ROOT}/oh-my-zsh/oh-my-zsh.sh
source ${ZSH_ROOT}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ${ZSH_ROOT}/zsh-titles/titles.plugin.zsh
unset DISABLE_AUTO_UPDATE

# Timeout

KEYTIMEOUT=200
export PROMPT_MODE=

# Aliases

alias -s c=vim
alias -s h=vim
alias -s toml=vim
alias -s md=vim

alias mv='mv -v'
alias cdl='cd ~/var/downloads'
alias clr='clear'

alias g='git'
alias d='dirs -v | head -20'
alias h='cd ~'
alias a='cat ${ZSH_ROOT}/zshrc.sh | grep ^alias | sort'

alias ga='git add'
alias gamd='git amd'
alias gama='git ama'
alias gamna='git amna'
alias gamupd='git amupd'
alias gb='git branch -v'
alias gbd='git branch -D'
alias gbl='git fancy-branch-list'
alias gbm='git branch -M'
alias gbn='git rev-parse --abbrev-ref HEAD'
alias gbr='git branch -v -r'
alias gbu='git branch -u'
alias gbuo='git buo'
alias gbuom='git buom'
alias gc='git commit'
alias gca='git commit -a'
alias gcam='git commit -a -m'
alias gcam_='git cam "Various updates (no details)"'
alias gcam_p='gcam_ && gp'
alias gchr='git crpk'
alias gcm='git cm'
alias gcm_='git cm "Various updates (no details)"'
alias gco='git co'
alias gcont='git cont'
alias gcp1='git chop1'
alias gcp2='git chop2'
alias gd='git diff'
alias gdh='git diff HEAD'
alias gdc='git diff --cached'
alias gdch='git diff --cached HEAD'
alias gelc='git elc'
alias gf='git fetch'
alias gfme='git fetch da-x'
alias gfre='git fetch && git rebase'
alias gftl='git ftl'
alias gg='git grep'
alias gl1='git log -1'
alias gl='git log'
alias glast='git last'
alias glc1='git lc1'
alias glc='git lc'
alias glcr='git lcr'
alias gmed='git mediate'
alias gn='git next'
alias gnc='git anticom'
alias goc='git commit-orig'
alias godo='git todo'
alias gp='git push'
alias gr-='git r-'
alias gr-h='git r-h'
alias gr='tig refs'
alias grb='git rebase'
alias grbh='git rbh'
alias grbi='git rbi'
alias grbt='git rbt'
alias gron='git ron'
alias grt='git remote'
alias gs='git status'
alias gsh1='git sh1'
alias gsh2='git sh2'
alias gsh3='git sh3'
alias gsh='git show'
alias gti='git'
alias gtb='git tracking-branch'
alias gts='git ctags'
alias gwh='git-wtb-help'
alias gwd='git-wtb-remove'
alias gws='git-wtb-switch'
alias gwr='git-wtb-rename'
alias gwl='git worktree list'

alias v-gls='v $(git ls-files ; git list-untracked)'
alias fm='exo-open --launch FileManager'
alias pfe='pty-for-each'
alias pfes="pfe single '' --"
alias rgsl='rg --sort-files --color always'
alias rex1='rex wait-on -n 1 -- '
alias rex2='rex wait-on -n 2 -- '
alias rex3='rex wait-on -n 3 -- '

which lsd 2>/dev/null >/dev/null
if [[ "$?" == "0" ]] ; then
    alias ll='lsd -l'
else
    which exa 2>/dev/null >/dev/null
    if [[ "$?" == "0" ]] ; then
	alias ll='exa -l'
    fi
fi

# Editor

which nvim 2>/dev/null >/dev/null
if [[ "$?" == "0" ]] ; then
    alias v='nvim'
    export EDITOR="nvim"
    VISUAL="nvim"
else
    alias v='vim'
    export EDITOR="vim"
    VISUAL="vim"
fi

# Invoke vim Gg directly from command line

vgg() { v -c "Gg $@" }

# Tmux pane background color

if [ -n "$TMUX" ]; then
    get-bgc() {
	v=$(tmux select-pane -g | grep 'bg=#' | awk -F'bg=#' '{print $2}')
    }

    bgc() {
	tmux select-pane -P "bg=#$1"
    }

    # When running sudo, change background to red
    sudo() {
	oldbgc=$(get-bgc)
	if [[ $oldbgc == '' ]] ; then
	    oldbgc=000000
	fi
	bgc 200000
	/usr/bin/sudo "$@"
	e=$?
	bgc ${oldbgc}
	return $e
    }
fi

if [ -e /etc/redhat-release ] ; then
    grep -q CentOS /etc/redhat-release
    if [[ "?$"  == "0" ]] ; then
	alias bring='sudo yum install'
    else
	alias bring='sudo dnf install'
    fi
else
    alias bring='sudo apt-get install'
fi

# Frequent typos

alias gerp='grep'
alias gre='grep'
alias gepr='grep'
alias rload='reload'
alias rloa='reload'
alias dc='cd'
alias dmseg='dmesg'
alias psf='ps --forest'
alias psfa='psf -fe'

# Env

GREP_COLORS='ms=38;5;47;1:mc=01;34:sl=:cx=:fn=38;5;117:ln=38;5;32:bn=31:se=38;5;50;1'

# Terminal setup

my-noop-func() { }
zle -N my-noop-func

stty -ixon
stty stop undef
stty start undef

bindkey "^[[5;30001~" accept-line
bindkey "^[[5;30002~" accept-line
bindkey "^[[5;30003~" accept-line
bindkey "^[[5;30005~" accept-line

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

fpath=($HOME/.zsh/completions $fpath)

autoload -U compaudit compinit
autoload -U colors && colors

# Other options

setopt auto_cd
setopt multios

# History

SAVEHIST=100000
HISTSIZE=100000
export HISTFILE=${ZSH_ROOT}/history

setopt no_inc_append_history
setopt histignoredups
setopt histignorealldups
setopt histignorespace
setopt histfindnodups
setopt extended_history
setopt hist_verify
setopt inc_append_history

unsetopt share_history

#
# Per-directory history
#
# Based on a modified `zsh' from:
#
#    https://github.com/da-x/zsh/tree/per-directory-history
#

export FZF_CTRL_R_OPTS='--exact'

# Setup superhist
#------------------------------------------------------------------------------------------

function _fc_per_directory_history() { fc -crl 1 }
function _fc_per_directory_history_fetch() { zle vi-fetch-history -n $1 }
function _fc_history() { fc -rl 1 }
function _fc_history_fetch() { zle vi-fetch-history -n $1 }
function _fc_retrive() { fc -rl 1 }

if [[ -e ${ZSH_ROOT}/superhist/bin/superhist ]] ; then
    SAVEHIST=1000
    HISTSIZE=1000

    function _superhist_root() {
	echo $(dirname ${HISTFILE})/superhist
    }

    _superhist_proc_res=
    _superhist=true
    _superhist_idx=0
    _superhist_term_id=$(tty)

    function _superhist-addhistory() {
	local cmd=$(echo $@ | tr '\n' ' ')
	local SUPERHIST_ROOT=$(_superhist_root)

	if [[ "${cmd}" =~ '^(\s)*$' ]]; then
	    true
	else
	    _superhist_command=y
	    _superhist_idx=$(($_superhist_idx + 1))
	    ${ZSH_ROOT}/superhist/bin/superhist --root ${SUPERHIST_ROOT} add \
		-i ${_superhist_idx} \
		-t ${_superhist_term_id} \
		-x $(date +%s) \
		-w $PWD \
		-c "$@"
	fi
    }

    function _superhist-precmd() {
	local _superhist_exitcode=${?}
	local SUPERHIST_ROOT=$(_superhist_root)
	if [[ "$_superhist_command" == "y" ]] ; then
	    unset _superhist_command
	    ${ZSH_ROOT}/superhist/bin/superhist --root ${SUPERHIST_ROOT} add \
		-i ${_superhist_idx} \
		-t ${_superhist_term_id} \
		-x $(date +%s) \
		-e "${_superhist_exitcode}"
	fi
    }

    function _fc_per_directory_history() {
	local SUPERHIST_ROOT=$(_superhist_root)
	${ZSH_ROOT}/superhist/bin/superhist --root ${SUPERHIST_ROOT} fc -s 1 -w $(realpath $PWD)
    }

    function _fc_history() {
	local SUPERHIST_ROOT=$(_superhist_root)
	${ZSH_ROOT}/superhist/bin/superhist --root ${SUPERHIST_ROOT} fc -s 1
    }

    function _fc_per_directory_history_fetch() {
	local SUPERHIST_ROOT=$(_superhist_root)
	BUFFER=$(${ZSH_ROOT}/superhist/bin/superhist --root ${SUPERHIST_ROOT}  fc -s 1 -w $(realpath $PWD) -f $1)
	zle end-of-buffer-or-history
    }

    function _fc_history_fetch() {
	local SUPERHIST_ROOT=$(_superhist_root)
	BUFFER=$(${ZSH_ROOT}/superhist/bin/superhist --root ${SUPERHIST_ROOT}  fc -s 1 -f $1)
	zle end-of-buffer-or-history
    }

    function fzf-super-history-set-proc() {
	setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2> /dev/null
	local SUPERHIST_ROOT=$(_superhist_root)
	local prev_result=()
	if [[ "${_superhist_proc_res}" != "" ]] ; then
	    local prev_result=(-p ${_superhist_proc_res})
	fi

	_superhist_proc_res=$(${ZSH_ROOT}/superhist/bin/superhist \
	    --root ${SUPERHIST_ROOT} proc-add -w "$(realpath $PWD)" -c "${BUFFER}" -i \
	    ${prev_result[@]})

	fzf-super-history-handle-result

	zle reset-prompt
    }

    function _superhist_procedure_exec() {
	local idx=0
	local size=$(echo ${_superhist_proc_res} | jq '.exec_queue' - | jq length -)

	if [[ "${size}" == "0" ]] ; then
	    return -1
	fi

	echo
	echo "------ \e[1;37m Executing queue of size ${size} ------ \e[0m"

	while [[ $(($idx < $size )) == "1" ]] ; do
	    local cmd=$(echo ${_superhist_proc_res} | jq '.exec_queue' - | jq -r '.['$idx'][1]')
	    echo
	    echo "[\e[1;32m$idx\e[0m]: \e[1;37m${cmd}\e[0m"
	    echo
	    eval $(echo ${_superhist_proc_res} | jq '.exec_queue' - | jq -r '.['$idx'][1]')  </dev/tty

	    if [[ "$?" != "0" ]] ; then
		local save=$?
		echo
		echo "\e[1;31mAborted\e[0m sequence aborted due to error: ${save}"
		echo
		return -1
	    fi

	    idx=$(($idx + 1))
	done

	return 0
    }

    function fzf-super-history-handle-result() {
	while [ 1 ] ; do
	    local mode=$(echo ${_superhist_proc_res} | jq -r .mode -)

	    if [[ "$mode" == "execute" ]] ; then
		_superhist_procedure_exec

		if [[ "$?" == "0" ]] ; then
		    fzf-super-history-pick-proc
		else
		    break
		fi
	    else
		break
	    fi
	done
    }

    function fzf-super-history-pick-proc() {
	setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2> /dev/null
	local SUPERHIST_ROOT=$(_superhist_root)
	local prev_result=()
	if [[ "${_superhist_proc_res}" != "" ]] ; then
	    local prev_result=(-p ${_superhist_proc_res})
	fi

	_superhist_proc_res=$(${ZSH_ROOT}/superhist/bin/superhist \
	    --root ${SUPERHIST_ROOT} proc-pick -w "$(realpath $PWD)" ${prev_result[@]})
    }

    function fzf-super-history-pick-proc-exec() {
	fzf-super-history-pick-proc
	fzf-super-history-handle-result
	zle reset-prompt
    }

    autoload -U add-zsh-hook
    add-zsh-hook zshaddhistory _superhist-addhistory
    add-zsh-hook precmd _superhist-precmd
fi

# Per-directory history provided by superhist
fzf-per-directory-history-widget() {
  local selected num
  setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2> /dev/null
  selected=( $(_fc_per_directory_history |
    FZF_DEFAULT_OPTS="--ansi --height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort $FZF_CTRL_R_OPTS --query=${(qqq)LBUFFER} +m" $(__fzfcmd)) )
  local ret=$?
  if [ -n "$selected" ]; then
    num=$selected[1]
    if [ -n "$num" ]; then
      _fc_per_directory_history_fetch $num
    fi
  fi
  zle reset-prompt
  return $ret
}

zle     -N   fzf-per-directory-history-widget
bindkey '^Ne' fzf-per-directory-history-widget
bindkey '^Nh' fzf-per-directory-history-widget
bindkey '^N^H' fzf-per-directory-history-widget

# CTRL-R - Paste the selected command from history into the command line
fzf-super-history-widget() {
    local selected num
    setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2> /dev/null
    selected=( $(_fc_history |
      FZF_DEFAULT_OPTS="--ansi --height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort $FZF_CTRL_R_OPTS --query=${(qqq)LBUFFER} +m" $(__fzfcmd)) )
    local ret=$?
    if [ -n "$selected" ]; then
      num=$selected[1]
      if [ -n "$num" ]; then
        _fc_history_fetch $num
      fi
    fi
    zle reset-prompt
    return $ret
}

zle     -N   fzf-super-history-widget
bindkey '^R' fzf-super-history-widget

if [[ $_superhist == true ]] ; then
    zle     -N   fzf-super-history-set-proc
    bindkey '^N^[[2~' fzf-super-history-set-proc
    zle     -N   fzf-super-history-pick-proc-exec
    bindkey '^N\\' fzf-super-history-pick-proc-exec
fi

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

emit-picked-git-branch-name() {
    local s="$(git show-ref | grep " refs/remotes/" | cut -c55- | fzf)"

    # Append 's' as if it was written manually, advancing the cursor
    BUFFER="${BUFFER[1,$(($CURSOR))]}$s${BUFFER[$(($CURSOR + 1)),100000]}"
    CURSOR=$(($CURSOR + $#s))
}
zle -N emit-picked-git-branch-name

my-zsh-git-checkout() {
    local name=$(git-mru-branch | fzf --tac -e +s)
    if [[ ${name} == "" ]] ; then
	return
    fi
    echo
    git-wtb-switch ${name}
    zle accept-line
}
zle -N my-zsh-git-checkout

my-zsh-git-worktree-checkout() {
    local name=$(git-mru-branch | fzf --tac -e +s)
    if [[ ${name} == "" ]] ; then
	return
    fi
    echo
    git-wtb-switch -c ${name}
    zle accept-line
}
zle -N my-zsh-git-worktree-checkout

my-zsh-git-log() {
    git log
}
zle -N my-zsh-git-log

my-zsh-CtrlG_j() {
    nvim -c "call MyFZFDiffHunks('HEAD~1', 'full')"
}
zle -N my-zsh-CtrlG_j

my-zsh-CtrlG_d() {
    git-fzf-diff
}
zle -N my-zsh-CtrlG_d

my-zsh-CtrlG_D() {
    nvim -c "call MyFZFDiffHunks('HEAD', 'full')"
}
zle -N my-zsh-CtrlG_D

my-zsh-DiffHunksCached() {
    nvim -c "call MyFZFDiffHunks('--cached', 'full')"
}
zle -N my-zsh-DiffHunksCached

my-zsh-git-diff() {
    git diff
}
zle -N my-zsh-git-diff

my-zsh-git-diff-cached() {
    git diff --cached
}
zle -N my-zsh-git-diff-cached

my-zsh-git-status() {
    git status | less -R
}
zle -N my-zsh-git-status

my-zsh-ls() {
    pfes lsd -l | less -R
}
zle -N my-zsh-ls

my-zsh-edit-git-file() {
    local picked=$(git ls-files | fzf -m -1 -0)
    if [[ "$picked" != "" ]] ; then
	${EDITOR} $(echo ${picked})
    fi
}
zle -N my-zsh-edit-git-file

my-zsh-edit-status-file() {
    local picked=$(git status --porcelain | fzf -m -1 -0 | awk -F" " '{print $2}')
    if [[ "$picked" != "" ]] ; then
	${EDITOR} $(echo ${picked})
    fi
}
zle -N my-zsh-edit-status-file

my-zsh-edit-HEAD-file() {
    local picked=$(git show  --name-status --pretty='' | fzf -m -1 -0 | awk -F" " '{print $2}')
    if [[ "$picked" != "" ]] ; then
	${EDITOR} $(echo ${picked})
    fi
}
zle -N my-zsh-edit-HEAD-file

my-zsh-CtrlG_q() {
    # Edit conflicted files
    local picked=$(git diff --name-only --diff-filter=U | fzf -m -1 -0)
    if [[ "$picked" != "" ]] ; then
	${EDITOR} $(git rev-parse --show-toplevel)/${picked}
    fi
}
zle -N my-zsh-CtrlG_q

# Ensure precmds are run after cd
fzf-redraw-prompt() {
  # We use this despite:
  #  [zsh] Don't run precmd hooks in cd widget (#2340)
  #  43b3b907f8b73efdeb6a55ba995c81ab708baf32
  local precmd
  for precmd in $precmd_functions; do
    $precmd
  done
  zle reset-prompt
}
zle -N fzf-redraw-prompt

my-zsh-cd-parent() {
    cd ..
    zle fzf-redraw-prompt
}
zle -N my-zsh-cd-parent

bindkey "^[ll" my-zsh-ls
bindkey "^[l^[l" my-zsh-ls

# C
fzf-cd-tmux-paths() {
  local cmd="tmux-paths"
  setopt localoptions pipefail no_aliases 2> /dev/null
  local dir="$(eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --no-sort --reverse $FZF_DEFAULT_OPTS $FZF_ALT_C_OPTS" $(__fzfcmd) +m)"
  if [[ -z "$dir" ]]; then
    zle redisplay
    return 0
  fi
  cd "$dir"
  unset dir # ensure this doesn't end up appearing in prompt expansion
  local ret=$?
  zle fzf-redraw-prompt
  return $ret
}
zle     -N    fzf-cd-tmux-paths

# Ctrl-'
bindkey '^[[5;30024~' fzf-cd-tmux-paths

# C-\
bindkey "^\\" fzf-cd-widget

# Ctrl-backspace
bindkey "^H" my-zsh-cd-parent
bindkey "^]" fzf-file-widget
bindkey -r "^[l"

batless() {
    LESS='-R' LESSOPEN="|bat --color=always --style=plain %s" less "$@"
}

export FZF_ALT_C_COMMAND="fd -t d ."
export FZF_DEFAULT_COMMAND="fd ."
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Ctrl-F1
show-runtime-help() {
    batless ${ZSH_ROOT}/README.md
}

zle -N show-runtime-help
bindkey "^[[1;5P" show-runtime-help

# C-g bindings for Git

bindkey "^GB" emit-current-git-branch-name
bindkey "^GH" emit-current-git-hash
bindkey "^GP" emit-picked-git-branch-name
bindkey "^GR" emit-current-git-root-relative
bindkey "^GT" emit-current-git-path-to-root
bindkey "^Gc" my-zsh-git-checkout
bindkey "^GC" my-zsh-git-worktree-checkout
bindkey "^Gd" my-zsh-CtrlG_d
bindkey "^G^d" my-zsh-CtrlG_d
bindkey "^GD" my-zsh-CtrlG_D
bindkey "^Ge" my-zsh-edit-status-file
bindkey "^G^E" my-zsh-edit-status-file
bindkey "^Gf" my-zsh-edit-git-file
bindkey "^G^F" my-zsh-edit-git-file
bindkey "^Gh" my-zsh-edit-HEAD-file
bindkey "^G^H" my-zsh-edit-HEAD-file
bindkey "^Gq" my-zsh-CtrlG_q
bindkey "^G^q" my-zsh-CtrlG_q
bindkey "^Gl" my-zsh-git-log
bindkey "^G^L" my-zsh-git-log
bindkey "^Gj" my-zsh-CtrlG_j
bindkey "^G^j" my-zsh-CtrlG_j
bindkey "^Gn" my-zsh-git-diff-cached
bindkey "^G^N" my-zsh-git-diff-cached
bindkey "^Gs" my-zsh-git-status
bindkey "^G^S" my-zsh-git-status

# Edit the current command line in $EDITOR

autoload -U edit-command-line
zle -N edit-command-line
bindkey '^[e' edit-command-line

# Prompt

# (took stuff from https://github.com/Parth/dotfiles)

autoload -U colors && colors

HOST_NAME_PROMPT_OVERRIDE=$(hostname)
HOST_PC_PROMPT_COLOR="$fg_bold[magenta]"

if [[ -e ${ZSH_ROOT}/per-host-config.zsh ]] ; then
    if [[ ! -h "${ZSH_ROOT}/per-host-config.zsh" ]] ; then
	echo ${ZSH_ROOT}/per-host-config.zsh should be a symlink to a
	echo different place where it is unaffected by git clean in the
	echo ${ZSH_ROOT} directory.
    fi
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

# C-Insert
bindkey "^[[2;5~"    _narrow_to_region_marked

LAST_EXIT_STATUS_COLLECTED=1

function notify_unfocused_termination() {
    local elapsed=$1
    local exitcode=$2

    if [ ! -n "$TMUX" ]; then
	return
    fi

    # Name of the session for which this shell belongs
    local session_name=$(tmux display-message -p '#S')

    # Is this session focused on any client?
    tmux list-clients -t ${session_name} -F '#{client_flags}' | grep ',focused' > /dev/null

    if [[ "$?" = "0" ]] ; then
	# Session is in focus, but we may be focused in another window.

	# Tmux window ID of the pane in which the shell is executing.
	local pane_win=$(tmux list-panes -as -F '#{window_id}' -f "#{==:#{pane_id},"${TMUX_PANE}"}")

	# Tmux window ID of the currently focused window in the session.
	local focus_win=$(tmux list-windows -F '#{window_id}' -f '#{window_active}' -t ${session_name})

	if [[ ${pane_win} == ${focus_win} ]] ; then
	    # Focused
	    return
	fi
    fi

    local lockfile=${XDG_RUNTIME_DIR}/unfocused-terminations.lock
    local logfile=${XDG_RUNTIME_DIR}/unfocused-terminations.log
    local name=$(tmux list-panes -as -F '#{window_name}' -f "#{==:#{pane_id},"${TMUX_PANE}"}")
    local index=$(tmux list-panes -as -F '#{window_index}' -f "#{==:#{pane_id},"${TMUX_PANE}"}")
    echo "$(date +%s),${session_name},${index},${name},${TMUX_PANE},${exitcode}" >> ${logfile}.$$
    flock ${lockfile} bash -c "cat ${logfile}.$$ >> ${logfile}"
    rm -f ${logfile}.$$
}

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

    # Mode

    if [[ $PROMPT_MODE != "" ]] ; then
	for i in $(echo $PROMPT_MODE); do
	    PS1+="%{$bg[blue]$fg[black]%}$i%{$reset_color%} "
	done
    fi

    # Time

    PS1+="${dh}%D{%H:%M}%{$reset_color%}"

    # Git status
    if git rev-parse --is-inside-work-tree 2> /dev/null | grep -q 'true' ; then
	PS1+=' '
	PS1+="%{$fg_bold[cyan]%}<%{$reset_color$fg[cyan]%}$(git rev-parse --abbrev-ref HEAD 2>/dev/null)%{$reset_color%}"
	if [ "$(git config core.prompt-disable)" != "true" ] ; then
	    if [ $(git -c core.checkStat=minimal status --short | wc -l) -gt -1 ]; then
		PS1+="%{$fg[red]%}+$(git -c core.checkStat=minimal status --short | wc -l | awk '{$1=$1};1')%{$reset_color%}"
	    fi
	fi
	PS1+="%{$fg_bold[cyan]%}>%{$reset_color$fg[cyan]%}"
	PS1+=$'\n'
    fi

    # Timer: http://stackoverflow.com/questions/2704635/is-there-a-way-to-find-the-running-time-of-the-last-executed-command-in-the-shel
    if [[ $_elapsed[-1] -ne 0 ]]; then
	notify_unfocused_termination $_elapsed[-1] $LAST_EXIT_CODE
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

    if [[ "$VIMRUNTIME" != "" ]] ; then
	PS1+="%{$gh2%} $fg[yellow]<%{$fg_bold[yellow]%}VIM%{$gh2%}$fg[yellow]>%{$reset_color%}"
    fi

    # End

    PS1+="%{$gh2%} ]"

    if [[ $PROMPT_MODE != "" ]] ; then
	PS1+="%{$bg[blue]$fg[black]%}"
    fi

    PS1+="%{$fg_bold[white]%}\$%{${reset_color}%} "
}

precmd_functions+=set_prompt

if [ -n "$TMUX" ]; then
    function tmux-refresh {
	for i in $(tmux show-environment | grep -v "^-") ; do 
	    export $i
	done
	tmux show-environment | grep "^-XAUTHORITY" > /dev/null
	if [[ $? == 0 ]] ; then
	    unset XAUTHORITY
	fi
	_last_tmux_refresh=$SECONDS
    }

    function tmux-check-refresh {
	if [[ $(( SECONDS-_last_tmux_refresh >= 3)) == 1 ]] ; then
	    tmux-refresh
	fi
    }
else
    function tmux-refresh { }

    function tmux-check-refresh { }
fi

preexec () {
    LAST_EXIT_STATUS_COLLECTED=0
    (( ${#_elapsed[@]} > 1000 )) && _elapsed=(${_elapsed[@]: -1000})
    _start=$SECONDS

    tmux-check-refresh

    if [[ "${_notify_activated}" == "1" ]] ; then
	_desktop_at_preexec=$(xdotool get_desktop)
    fi
}

tmux-refresh

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

git-watch() {
    rex wait-on -g . -c -- "$@"
}

# Git worktree+branches handy commands
#------------------------------------------------------------------------------------------

git-wtb-path() {
    WTB_PATH=$(git config wtb.path)
    if [[ "${WTB_PATH}" == "" ]] ; then
	echo "Not configured."
	echo
	echo "Run: git config wtb.path [path]"
	echo ""
	echo "For example: git config wtb.path /tmp/$USER/git/$(pwd)"
	return 1
    fi
    return 0
}

git-wtb-help() {
    echo "gws - git-wtb-switch [name] (-c/--create) --base base"
    echo "gwr - git-wtb-rename [new-name]"
    echo "gwd - git-wtb-remove [name] (-f)"
    echo "gwh - git-wtb-help"
    echo "gwl - git worktree list"
}

git-wtb-rename() {
    # Rename current Git branch *and* git worktree directory basename, plus
    # change to the moved worktree directory.
    newname=${1}
    if [[ ${newname} == "" ]] ; then
	return
    fi

    git-wtb-path

    if [[ "$?" != "0" ]] ; then
	return
    fi

    while read dir details ; do
	if [[ "${dir}" == "$(pwd)" ]] ; then
	    local branch=$(echo ${details} | awk -F'[\\]\\[]' '{print $2}')
	    if [[ "${WTB_PATH}/${branch}" == "${dir}" ]] ; then
		newdirname=${WTB_PATH}/${newname}
		if [[ -d ${newdirname} ]] ; then
		    echo Already exists
		    break
		fi

		mkdir -p $(dirname ${newdirname})
		git worktree move ${dir} ${newdirname}
		git branch -M ${last} ${newname}
		cd ${newdirname}
	    fi
	    break
	fi
    done < <(git worktree list)
}

git-wtb-remove() {
    local name=""
    local force=0
    local removeparams=""

    while [[ $# != 0 ]] ; do
	if [[ "$1" == "-f" ]] ; then
	    echo "$1" xx
	    removeparams="--force"
	    force=1
	    shift
	    continue
	fi
	if [[ "$name" != "" ]] ; then
	    echo "Name already specified"
	    return 1
	fi
	name="$1"
	shift
	continue
    done

    if [[ ${name} == "" ]] ; then
	name=$(git branch --show-current)
    fi

    if [[ ${name} == "" ]] ; then
	echo "No current branch name"
	return 1
    fi

    local maintree=""
    local mainbranch=""
    while read dir details ; do
	local branch=$(echo ${details} | awk -F'[\\]\\[]' '{print $2}')
	if [[ "$maintree" == "" ]]; then
	    maintree=$dir
	    mainbranch=$branch
	fi
	if [[ "${branch}" == "${name}" ]] ; then
	    git worktree remove ${removeparams} ${dir}
	    if [[ "$?" == "0" ]] ; then
		cd ${maintree}
	    else
		return 1
	    fi
	    return
	fi
    done < <(git worktree list)
}

git-wtb-switch() {
    # Switch to a worktree's directory, based on its branch name
    local name=""
    local create=0
    local base=""

    while [[ $# != 0 ]] ; do
	if [[ "$1" == "-c" ]] || [[ "$1" == "--create" ]] ; then
	    create=1
	    shift
	    continue
	fi
	if [[ "$1" == "-b" ]] || [[ "$1" == "--base" ]] ; then
	    shift
	    base="$1"
	    shift
	    continue
	fi
	if [[ "$name" != "" ]] ; then
	    echo "Name already specified"
	    return 1
	fi
	name="$1"
	shift
    done

    if [[ ${name} == "" ]] ; then
	echo "Name not specified"
	return
    fi

    local maintree=""
    local mainbranch=""
    while read dir details ; do
	local branch=$(echo ${details} | awk -F'[\\]\\[]' '{print $2}')
	if [[ "$maintree" == "" ]]; then
	    maintree=$dir
	    mainbranch=$branch
	fi
	if [[ "${branch}" == "${name}" ]] ; then
	    if [[ ! -d ${dir} ]] ; then
		local wd=$(git rev-parse --git-common-dir)/worktrees
		local found=0

		for i in ${wd}/*; do
		    if [[ "$(cat ${i}/gitdir)" == "${dir}/.git" ]] ; then
			echo Worktree missing, recovering
			found=1
			mkdir -p ${dir}
			echo "gitdir: $(realpath ${i})" > ${dir}/.git
			cd ${dir}
			git checkout -- .
			cd - > /dev/null
			break
		    fi
		done

		if [[ "${found}" == "0" ]] ; then
		    echo Worktree missing, RECREATING
		    git worktree remove ${dir}
		    mkdir -p $(dirname ${dir})
		    git worktree add ${dir} ${branch}
		fi
	    fi
	    cd ${dir}
	    local branch_ref="$(git rev-parse --git-common-dir)/refs/heads/${branch}"
	    if [[ -e ${branch_ref} ]] ; then
		touch ${branch_ref}
	    fi
	    return
	fi
    done < <(git worktree list)

    if [[ "$create" == "1" ]] ; then
	git-wtb-path
	if [[ "$?" != "0" ]] ; then
	    return 1
	fi

	branchinfo=$(git show-ref refs/heads/${name})

	if [[ "${branchinfo}" == "" ]] ; then
	    if [[ "${base}" != "" ]] ; then
		if [[ "$(git rev-parse ${base})" == "" ]] ; then
		    echo "Base ${base} does not resolve"
		    return 1
		fi
	    fi

	    if [[ "${base}" == "" ]] ; then
		echo "No such local branch"
		return 1
	    else
		git branch --track ${name} ${base}
	    fi
	fi

	git worktree add ${WTB_PATH}/${name} ${name}
	cd ${WTB_PATH}/${name}
	return 0
    fi

    if [[ "$mainbranch" == "$branch" ]] && [[ "$mainbranch" == "$name" ]] ; then
	return 0
    fi

    local toplevel=$(git rev-parse --show-toplevel)
    if [[ "${toplevel}" != "${maintree}" ]] ; then
	if [[ "$(basename ${toplevel})" != "$name" ]] ; then
	    # The checkout is redirected to the main worktree only if the
	    # name of the branch does not match the name of the directory
	    # of the worktree.
	    cd ${maintree}
	fi
    fi

    git checkout ${name}
}

# Envix overrides
#------------------------------------------------------------------------------------------

envix_path=$(which envix 2>/dev/null)
if [[ "${envix_path}" != "" ]] then
    envix_prev_pwd="/"

    function envio_refresh_context() {
	${envix_path} --previous "$(realpath ${envix_prev_pwd})" --current $(realpath ${PWD}) | source /dev/stdin
	envix_prev_pwd=${PWD}
    }

    envio_refresh_context
    case $- in
       *i*)
	  autoload -U add-zsh-hook
 	  add-zsh-hook chpwd envio_refresh_context
 	  ;;
       *) ;;
    esac
fi

# Setup backlinks
#------------------------------------------------------------------------------------------

declare -A backlinks
backlinks_nested=0

function loadback_links() {
    for i in $(find ~ -maxdepth 1 -type l | grep -v "${HOME}/[.]") ; do
	local link=$(readlink ${i})
	backlinks["${HOME}/$link"]=${i}
    done
}

function __check_backlink() {
    if [[ "${backlinks_nested}" == "1" ]] ; then
	return
    fi

    local dest=${backlinks["${PWD}"]}
    if [[ "${dest}" != "" ]] && [[ -d ${dest} ]]; then
	backlinks_nested=1
	cd ${dest}
	backlinks_nested=0
    fi
}

loadback_links
unset -f loadback_links
autoload -U add-zsh-hook
add-zsh-hook chpwd __check_backlink
