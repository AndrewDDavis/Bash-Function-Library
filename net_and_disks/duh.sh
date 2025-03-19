duh() {

    : "Print sorted disk usage of files in a directory tree

    Usage: duh-sort [du-options] [path-root]

    This runs 'du -hcD' to print file sizes using human-readable prefix units, and a
    grand-total of disk usage. If the path-root is omitted, the current directory is
    used.

    By default, only the sizes of the root directory and its subdirectories are
    printed. Use '-a' or a glob to print file sizes as well.

    Notable du options:

      -a (--all)
      : write counts for all files, not just directories

      -c (--total)
      : produce a grand total

      -D (--dereference-args)
      : Dereference only symlinks that are listed on the command line

      -h (--human-readable)
      : print sizes in human readable format (e.g., 1K 234M 2G)

      -s (--summarize)
      : display only a total for each argument, not for the files it contains

      -S (--separate-dirs)
      : when printing directory sizes, do not include size of subdirectories

      --time[=...]
      : show last modification time, or others using the argument

      -x (--one-file-system)
      : do not cross file-system boundaries
    "

	[[ $# -eq 1  && $1 == @(-h|--help) ]] &&
    	{ docsh -TD; return; }

    command du -hc "$@" \
        | command sort -h
}
