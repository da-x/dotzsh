#!/bin/bash

set -x
set -eu

e=0

tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
bin=${tmp_dir}/superhist.exe

./build.sh --dest ${bin}

export HISTFILE=${tmp_dir}/history

${bin} add -i 0 -t /dev/pts/10 -x 1600000000 -s
${bin} add -i 1 -t /dev/pts/10 -x 1600000001 -c "command 1" -w "/tmp"
${bin} add -i 1 -t /dev/pts/10 -x 1600000002 -e 0
${bin} add -i 3 -t /dev/pts/10 -x 1600000003 -c "command 2" -w "/tmp/sub"
${bin} add -i 3 -t /dev/pts/10 -x 1600000004 -e 2
${bin} add -i 5 -t /dev/pts/10 -x 1600000005 -c "command 3" -w "/tmp/sub"
${bin} add -i 5 -t /dev/pts/10 -x 1600000006 -e 0

cat ${tmp_dir}/superhist/db.json

check_fc() {
    ${bin} fc

    if [[ "$(${bin} fc | wc -l)" != "3" ]] ; then
	e=1
    fi

    ${bin} fc -w /tmp/sub

    if [[ "$(${bin} fc -w /tmp/sub | wc -l)" != "2" ]] ; then
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

${bin} fc

rm -rf $tmp_dir

exit $e
