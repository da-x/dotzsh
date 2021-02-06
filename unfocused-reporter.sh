#!/bin/bash

# Will be replaced with a better program.

main() {
    clear
    local logfile=${XDG_RUNTIME_DIR}/unfocused-terminations.log
    local myrows
    local mycols

    tput civis

    print_line() {
	intensity=$1
	printf "\e[48;2;${intensity};${intensity};${intensity}m"
	local msg=""
	local cmsg=""
	msg+="$(date -d "@$ts")"
	msg+=" "
	msg+="${location}"
	msg+=" "
	msg+="${exit_code}"
	printf "%-${mycols}s" "${msg}"
	printf "\r\e[0m"
    }

    read myrows mycols < <(stty size)

    while read -r line ; do
	local ts=$(echo $line | awk -F" " '{print $1}')
	local location=$(echo $line | awk -F" " '{print $2}')
	local exit_code=$(echo $line | awk -F" " '{print $3}')
	local i=0;

	printf "\n"
	for i in $(seq 50 1 120) 0 ; do
	    printf "\e[48;2;$i;$i;${i}m"
	    local msg=""
	    local cmsg=""
	    msg+="$(date -d "@$ts" "+%H:%M:%S")"
	    msg+=" "
	    msg+="${location}"
	    if [[ ${exit_code} != "0" ]] ; then
		msg+=$(printf " (\e[38;2;255;0;0mfailed\e[38;2;255;255;255m)")
	    fi
	    printf "%-${mycols}s" "${msg}"
	    printf "\r\e[0m"
	    sleep 0.01
	done
    done < <(tail -n 1 -f ${logfile})
}

main
