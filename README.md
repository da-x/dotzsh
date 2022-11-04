List of `zsh` hot-keys that are enabled by this repository

Command line editing:

* `C-\` - FZF-pick a subdirectory to change to
* `C-'` - FZF-pick a directory to change to, out of the current directories
          of other open terminals of the user.
* `C-]` - FZF-pick files from current tree and paste into commandline
* `C-r` - FZF-pick commands from history and paste into commandline
* `C-n h` - FZF-pick commands from history for the current directory and paste into commandline
* `C-Insert` - Narrow to region. Allow editing a part of the commandline as a subcommand
               with the ability to bring commands from the history using `C-r`.
* `A-e` - Edit the current command line in $EDITOR
* `C-w` - Delete-backward the current word in the command line
* `A-d` - Delete/chop the current word at the command line
* `C-a` - Go to the beginning of the command line
* `C-e` - Go to the end of the command line
* `C-k` - Clear to the end of the command line
* `C-g P` - FZF-pick a git branch name to paste into commandline
* `C-g B` - Emit current git branch name
* `C-g H` - Emit current git HEAD hash
* `C-g T` - Emit current relative path to the Git root repo
* `C-g R` - Emit current relative path from the Git root repo

Other:

* `C-l` - Clear screen
* `C-h`, `C-Backspace` - Change directory to parent

Quick invocations (inquires):

* `C-g d` - My git-fzf-diff
* `C-g n` - Git diff --cached
* `C-g l` - Git log
* `C-g s` - Git status
* `C-g z` - Git show

Quick invocations (modifications):

* `C-g q` - Pick one of the Git conflicts to edit.
* `C-g e` - Open a list of Git files in status, and go edit one of them
* `C-g f` - Open a list of Git files in FZF, and go edit one of them
* `C-g h` - Open a list of Git files affected by the commit HEAD in FZF, and go edit one of them
* `C-g j` - Open Neovim with FZF to pick editing one of the changed hunks in HEAD with a preview of such hunk.
* `C-g c` - Do a 'Git checkout' to another branch, or switch to another work-tree with that branch currently checked-out.
