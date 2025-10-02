#!/bin/bash

which nvim 2>/dev/null >/dev/null
if [[ "$?" == "0" ]] ; then
    actualvim=nvim
    alias v='nvim'
    if [[ -x ~/.local/bin/xvim ]] ; then
	actualvim=xvim
	alias v='xvim'
    fi
    export EDITOR="${actualvim}"
    VISUAL="${actualvim}"
    alias vim="xvim"
    alias vi="xvim"
    alias oldvim="/usr/bin/vim"
else
    alias v='vim'
    export EDITOR="vim"
    VISUAL="vim"
fi
