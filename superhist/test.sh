#!/bin/bash

set -x
set -eu

e=0

tmp_dir=$(mktemp -d -t superhist-ci-XXXXXXXXXX)
mkdir -p ${tmp_dir}/superhist

./build.sh --dest ${tmp_dir}/superhist.exe
bin="${tmp_dir}/superhist.exe --root ${tmp_dir}/superhist"

${bin} add -i 0 -t /dev/pts/10 -x 1600000000 -s
${bin} add -i 1 -t /dev/pts/10 -x 1600000001 -c "command 1" -w "/tmp"
${bin} add -i 1 -t /dev/pts/10 -x 1600000002 -e 0
${bin} add -i 3 -t /dev/pts/10 -x 1600000003 -c "command 2" -w "/tmp/sub"
${bin} add -i 3 -t /dev/pts/10 -x 1600000004 -e 2
${bin} add -i 5 -t /dev/pts/10 -x 1600000005 -c "command 3" -w "/tmp/sub"
${bin} add -i 5 -t /dev/pts/10 -x 1600000006 -e 0

cat ${tmp_dir}/superhist/db.json

check_fc() {
    ${bin} fc -s 0

    if [[ "$(${bin} fc -s 0 | wc -l)" != "3" ]] ; then
	e=1
    fi

    ${bin} fc -w /tmp/sub -s 0

    if [[ "$(${bin} fc -s 0 -w /tmp/sub | wc -l)" != "2" ]] ; then
	e=1
    fi
}

check_fc

${bin} archive

ls -l ${tmp_dir}/superhist/archive
ls -l ${tmp_dir}/superhist

check_fc

${bin} add -i 5 -t /dev/pts/10 -x 1600000005 -c "command 4" -w "/tmp/sub"
${bin} add -i 5 -t /dev/pts/10 -x 1600000006 -e 0

${bin} fc -s 0

${bin} proc-add -a "procedure" -c "command" -w "/w"
${bin} proc-add -a "other-procedure" -c "other-command" -w "/w"
${bin} proc-add -c "unaliased" -w "/w"
${bin} proc-add -c "ls" -w "/w"
${bin} proc-add -c "export A=2" -w "/w"

if [[ $# != 0 ]] && [[ "$1" == "keep" ]] ; then
    set +x
    echo
    echo $tmp_dir
    echo
    echo export BUILD=\"./build.sh --dest ${tmp_dir}/superhist.exe\"
    echo export BIN=\"${bin}\"
    exit 0
fi

rm -rf $tmp_dir

exit $e
