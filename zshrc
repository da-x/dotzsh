#---------------------------------------------------------------------------
# Misc

zmodload zsh/parameter
export EDITOR=mcedit
setopt prompt_subst

#---------------------------------------------------------------------------
# History

setopt HISTIGNOREDUPS HISTIGNORESPACE EXTENDED_HISTORY
setopt INC_APPEND_HISTORY

HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh/history

if [ "$PREV_HISTFILE" != '' ] ; then
    HISTFILE=~/.zsh/history
fi

#---------------------------------------------------------------------------
# Aliases

alias           mv='mv -v'
alias           cdl='cd ~/var/downloads'
alias           clr='clear'
alias           gifme='git fetch da-x'
alias           gih='git show'
alias           gis='git status'
alias           gipc='git pushc'
alias           gic='git co'
alias           gid='git diff'
alias           gif='git fetch'
alias           gibr='git branch -D'
alias           gib='git branch -v'
alias           gilc='git list-clones'
alias           gglc='gilc ~/dev | grep '
alias           gil='git log'
alias           gifa='git last'
alias           gin='git next'
alias           giri='git rebI'
alias           gifre='gif && gire'
alias           gire='git reb'
alias           gamd='git amendNDA'
alias           gre='grep'
alias           hgre='grep-hist'
alias           alz='cat ~/.zsh/zshrc | grep ^alias | sort'

# Typos
alias           gerp='grep'
alias           rload='reload'
alias           rloa='reload'

grep-hist()	{ grep -a "$@" ~/.zsh/history | cut -c16- | uniq | grep --binary-files=text -v grep-hist }
reload()	{ source ~/.zshrc }
zedit()		{ mcedit ~/.zshrc ; reload }
cdr()		{ cd `realpath $1` }
grepword()	{ egrep -n --color "\b$1\b"  -R * }
hicode()	{ LESSOPEN="| ~/.zsh/src-hilite-lesspipe.sh %s" less -R "$@" }
exrpm()		{ rpm2cpio $1 | (mkdir -p $2 ; cd $2 && cpio -idmv) }

export LESSOPEN="|fancydiff file %s -e"
export LESS="-R"

function cd() {
  emulate -LR zsh

  if [[ $1 == 'b.'* ]]; then
    builtin cd ${${1/"b"}//"."/"../"}
  else
    builtin cd $*
  fi
}

#---------------------------------------------------------------------------
# Prompt

GIT_PROMPT_EXECUTABLE="haskell"
ZSH_THEME_GIT_PROMPT_CACHE="y"
source ~/.zsh/zsh-git-prompt/zshrc.sh

case $DUP_LIGHT_TERMINAL in
    1)
	c=`print -n "%{\033[1;38;2;127;0;127m%}"`
	Dc=`print -n "%{\033[0;36m%}"`
	g=`print -n "%{\033[0;38m%}"`
	b=`print -n "%{\033[1;36m%}"`
	gr=`print -n "%{\033[1;32m%}"`
	ye=`print -n "%{\033[1;38;2;127;127;0m%}"`
	w=`print -n "%{\033[0;38m%}"`
	dg=`print -n "%{\033[1;36m%}"`
	dh=`print -n "%{\033[1;38;2;0;127;127m%}"`
	export GREP_COLORS='ms=38;5;47;1:mc=01;34:sl=:cx=:fn=38;5;117:ln=38;5;32:bn=31:se=38;5;50;1'
	;;
    *)
	c=`print -n "%{\033[1;35m%}"`
	Dc=`print -n "%{\033[0;36m%}"`
	g=`print -n "%{\033[0;37m%}"`
	b=`print -n "%{\033[1;36m%}"`
	gr=`print -n "%{\033[1;32m%}"`
	ye=`print -n "%{\033[1;33m%}"`
	w=`print -n "%{\033[1;37m%}"`
	dg=`print -n "%{\033[1;36m%}"`
	dh=`print -n "%{\033[0;36m%}"`
	export GREP_COLORS='ms=38;5;47;1:mc=01;34:sl=:cx=:fn=38;5;117:ln=38;5;32:bn=31:se=38;5;50;1'
	;;
esac


if [[ "$TERM" == "rxvt" ||  "$TERM" == "rxvt-unicode"  || "TERM" == "rxvt-unicode-256color" ]] { 
    title="%{\e]0;%m:%~ \C-g%}" 
} else {
    title=""
}

if [[ "PROMPT_MODE" == "" ]] {
    PROMPT_MODE=" "
}

function precmd {
	psvar[2]=$#jobstates; 
        [[ $psvar[2] -eq 0 ]] && psvar[2]=()
}

function parse_prompt_mode {
	echo "${PROMPT_MODE}\$(git_super_status)"
}

prompt=` \
print -n "${title}${w}[${dh}%D{%H:%M}${w} "; \
print -n "${ye}%n${w}@${c}%m${w}${gr}$(parse_prompt_mode) ${g}%~${w}]${g}%(2v:${g}[${b}%2v${g}]:)$ "`

unset dg
unset w
unset c
unset Dc
unset g

#---------------------------------------------------------------------------
# Key bindings

# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo
typeset -A key

key[Home]=${terminfo[khome]}

key[End]=${terminfo[kend]}
key[Insert]=${terminfo[kich1]}
key[Delete]=${terminfo[kdch1]}
key[Up]=${terminfo[kcuu1]}
key[Down]=${terminfo[kcud1]}
key[Left]=${terminfo[kcub1]}
key[Right]=${terminfo[kcuf1]}
key[PageUp]=${terminfo[kpp]}
key[PageDown]=${terminfo[knp]}

# setup key accordingly
[[ -n "${key[Home]}"    ]]  && bindkey  "${key[Home]}"    beginning-of-line
[[ -n "${key[End]}"     ]]  && bindkey  "${key[End]}"     end-of-line
[[ -n "${key[Insert]}"  ]]  && bindkey  "${key[Insert]}"  overwrite-mode
[[ -n "${key[Delete]}"  ]]  && bindkey  "${key[Delete]}"  delete-char
[[ -n "${key[Up]}"      ]]  && bindkey  "${key[Up]}"      up-line-or-history
[[ -n "${key[Down]}"    ]]  && bindkey  "${key[Down]}"    down-line-or-history
[[ -n "${key[Left]}"    ]]  && bindkey  "${key[Left]}"    backward-char
[[ -n "${key[Right]}"   ]]  && bindkey  "${key[Right]}"   forward-char

# Finally, make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
    function zle-line-init () {
        printf '%s' ${terminfo[smkx]}
    }
    function zle-line-finish () {
        printf '%s' ${terminfo[rmkx]}
    }
    zle -N zle-line-init
    zle -N zle-line-finish
fi

[[ -n "${key[PageUp]}"   ]]  && bindkey  "${key[PageUp]}"    history-beginning-search-backward
[[ -n "${key[PageDown]}" ]]  && bindkey  "${key[PageDown]}"  history-beginning-search-forward

if [ "x$CUSTOM_ZSH_SOURCE" != "x" ] ; then
    source $CUSTOM_ZSH_SOURCE
    unset $CUSTOM_ZSH_SOURCE
fi

# Ctrl-left, Ctrl-right
bindkey "^[Oc" forward-word
bindkey "^[Od" backward-word

# Free up Ctrl-S, Ctrl-Q
stty stop undef
stty start undef

#---------------------------------------------------------------------------
# Completions

fpath=(~/.zsh/completions $fpath)
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash

autoload -Uz compinit
compinit
