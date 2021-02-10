#!/bin/bash

set -e

dest=bin/superhist

while [[ $# != 0 ]] ; do
    if [[ "$1" == "--dest" ]] ; then
	shift
        dest=$1
        shift
        continue
    fi
    break
done

EXENAME=superhist
T=/tmp/$USER/rust/targets/`pwd`/target

mkdir -p $T
cargo build --release --target-dir ${T}

mkdir -p bin/
cp $T/release/${EXENAME} ${dest}
