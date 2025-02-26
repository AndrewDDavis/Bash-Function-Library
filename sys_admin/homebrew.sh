# Homebrew
# - see current config and env vars using: brew config

if [[ $( uname -s ) == Darwin && -n $( command -v brew ) ]]
then
    # I have symlinked /usr/local on Squamish
    # - this may cause problems when the brew script resolves the symlink with `pwd -P` (or doesn't?)
    # - brew doctor suggests also moving the tmp dir to the same volume
    [[ -d /Volumes/Files/usr/local ]] && export HOMEBREW_PREFIX=/Volumes/Files/usr/local
    [[ -d /Volumes/Files/usr/local/tmp ]] && export HOMEBREW_TEMP=/Volumes/Files/usr/local/tmp

    # do not check for secondary dependencies that could be upgraded every time you intall something
    export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1

    # Homebrew's gnu tools are preferred in some cases to BSD equivalents
    # - having some gnu tools available (e.g. sed, grep, find, mktemp) makes scripting easier
    # - some tools like chmod, chown have different features in BSD, probably shouldn't be masked
    # - so add coreutils to path, so they can be found with type -a, but let macOS tools rule
    # - NB, not necessary to add the gnuman dirs to MANPATH, because the libexec directories
    #   include a symlink for man -> gnuman
    path_check_add -b /usr/local/opt/coreutils/libexec/gnubin  \
                        /usr/local/opt/gnu-sed/libexec/gnubin    \
                        /usr/local/opt/findutils/libexec/gnubin  \
                        /usr/local/opt/grep/libexec/gnubin
fi
