#! /bin/sh

STYLE=~/.zsh/source-highlight.style

for source in "$@"; do
    case $source in
	*ChangeLog|*changelog) 
        source-highlight --failsafe -f esc --lang-def=changelog.lang --style-file=${STYLE} -i "$source" ;;
	*Makefile|*makefile) 
        source-highlight --failsafe -f esc --lang-def=makefile.lang --style-file=${STYLE} -i "$source" ;;
        *) source-highlight --failsafe --infer-lang -f esc --style-file=${STYLE} -i "$source" ;;
    esac
done
