List of `zsh` hot-keys that are enabled by this repository

Command line editing:

* `A-c`, `C-\` - FZF-pick a subdirectory to change to
* `C-t`, `C-]` - FZF-pick files from current tree and paste into commandline
* `C-r` - FZF-pick commands from history and paste into commandline
* `C-g P` - FZF-pick a git branch name to paste into commandline
* `C-w` - Delete-backward the current word in the command line
* `A-d` - Delete the current word at the command line
* `C-a` - Go to the beginning of the command line
* `C-e` - Go to the end of the command line
* `C-k` - Clear to the end of the command line
* `C-x` - Open a subsection of the command line to be used with `Ctrl-R`. Useful when creating `&&` chains
* `C-g B` - Emit current git branch name
* `C-g H` - Emit current git HEAD hash
* `C-g T` - Emit current relative path to the Git root repo
* `C-g R` - Emit current relative path from the Git root repo

Other:

* `C-l` - Clear screen

Quick invocations (inquires):

* `C-g d` - Git diff
* `C-g n` - Git diff --cached
* `C-g l` - Git log
* `C-g s` - Git status
* `C-g z1` - Git show HEAD~1
* `C-g z2` - Git show HEAD~2
* `C-g z3` - Git show HEAD~3
* `C-g z` - Git show

Quick invocations (modifications):

* `C-g e` - Open a list of Git files in status, and go edit one of them
* `C-g g` - Open a list of Git files in FZF, and go edit one of them
* `C-g h` - Open a list of Git files affected by the commit HEAD in FZF, and go edit one of them
* `C-g c` - Do a 'Git checkout' to another branch
