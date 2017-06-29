#!/usr/bin/env python

import os
import sys

def main():
    d = os.path.join(os.path.dirname(sys.argv[0]), "backlinks")
    rd = os.path.realpath(d)
    cwd = os.getcwd()

    for sym in os.listdir(d):
        sym_p = os.path.join(rd, sym)
        sym_rp = os.path.realpath(sym_p)
        if sym_rp == cwd:
            np = os.path.normpath(os.path.join(rd, os.readlink(sym_p)))
            print "cd %s" % (np, )
            return

main()

