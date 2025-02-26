# Python code path
# - appends all subdirs to sys.path so modules can be imported
[[ -d $HOME/Code/python ]] && {
    export PYTHONPATH=$( ls -1d ~/Sync/Code/python/*/ ~/Sync/Code/python/*/*/ |
                             tr '\n' ':' |
                                 sed 's@/:@:@g; s@:$@@' ):$PYTHONPATH
}

# Homebrew Python
# - on macOS, used to get python from Enthought, then gentoo, then fink, then
#   Enthought Canopy, then official python, now I use Homebrew python, installed to
#   /usr/local.
# - see installation and upgrade notes in `Python ... Notes.md.txt`
