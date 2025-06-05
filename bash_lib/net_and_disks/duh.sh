duh() {

    : """Print sorted disk usage of a directory tree

    Usage: duh [du-options] [path-root]

    This function prints the disk usage of directories under the specified tree, by
    running the 'du -hcSD' command (option details below). If the path-root argument
    is omitted, the current directory is used. The results are ordered using 'sort -h'.

    To print file sizes as well as directory usage, use '-a' or a glob pattern.

    Notable du options:

      -a (--all)
      : write counts for all files, not just directories

      -c (--total)
      : produce a grand total

      -D (--dereference-args)
      : dereference only symlinks that are listed on the command line

      -h (--human-readable)
      : print sizes in human readable format (e.g., 1K 234M 2G)

      -L (--dereference)
      : dereference all symbolic links

      -s (--summarize)
      : display only a total for each argument, not for the files it contains

      -S (--separate-dirs)
      : when printing directory sizes, do not include size of subdirectories

      --time[=...]
      : show last modification time, or others using the argument

      -x (--one-file-system)
      : do not cross file-system boundaries
    """

	[[ $# -eq 1  && $1 == @(-h|--help) ]] &&
    	{ docsh -TD; return; }

    command du -hcSD "$@" \
        | command sort -h
}
