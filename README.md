List of `zsh` hot-keys that are enabled by this repository

Command line editing:

* `C-t` - FZF-pick files from current tree and paste into commandline
* `C-r` - FZF-pick commands from history and paste into commandline
* `C-x` - Open a subsection of the command line to be used with `Ctrl-R`. Useful when creating `&&` chains
* `A-c` - FZF-pick a subdirectory to change to
* `A-g b` - Emit current git branch name
* `A-g p` - FZF-pick a git branch name to paste into commandline
* `A-g h` - Emit current git HEAD hash
* `A-g r` - Emit current relative path to the Git root repo
* `A-g R` - Emit current relative path from the Git root repo

Quick invocations (inquires):

* `A-g l` / `C-g g`- Git log
* `A-g s` - Git show
* `A-g s1` - Git show HEAD~1
* `A-g s2` - Git show HEAD~2
* `A-g s3` - Git show HEAD~3
* `A-g S` - Git status
* `A-g d` / `C-g d` - Git diff from HEAD
* `A-g D` / `C-g e` - Git diff of staged changes

Quick invocations (modifications):

* `C-g f` - Open a list of Git files in FZF, and go edit one of them
* `C-g s` - Open a list of Git files in status, and go edit one of them
* `A-g c` / `C-g t` - Do a 'Git checkout' to another branch
