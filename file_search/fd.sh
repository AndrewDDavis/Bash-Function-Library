#!/usr/bin/env bash

fd() {

    : "find variant with user-friendly syntax and defaults

    Usage: fd [options] [pattern] [path ...]

    This function calls either the \`fd\` or \`fdfind\` command to match filenames,
    with the following behaviour:

      - If the path is omitted, the tree under the current directory is searched.
        Symlinks are not followed, unless -L (--follow) is used. Mount points in the
        tree are searched, unless --one-file-system is used.

      - Substrings of file basenames are matched. The pattern is interpreted as a
        regular expression using the Rust regex engine, with syntax similar to ERE
        (<https://docs.rs/regex/1.0.0/regex/#syntax>).

          + Use -p (--full-path) to match full paths.

          + Use -F (--fixed-strings) to treat the pattern as a literal string, but
            still match as a substring.

          + Use -g (--glob) for glob pattern matching. This option also disables
            substring matching (exact filenames are matched). If combined with
            --full-path, '**' matches multiple path components.

          + Use --and to add additional patterns.

      - Smart-case matching is employed (cases-insensitive for lowercase patterns).

          + Modify this with -s (--case-sensitive) or -i (--ignore-case).

      - Hidden files are excluded, as well as files matched by the ignore files noted
        below. This function adds the --no-ignore-vcs option by default. Use
        --ignore-vcs or -I to override it.

          + Use -H (--hidden) to show hidden files. Use -I (--no-ignore) to disable all
            ignore files. Option -u (--unrestricted) is an alias for -HI.

          + \`fd\` respects the per-directory or per-repository files .gitignore,
            .git/info/exclude, .ignore, and .fdignore, and the global ignore files
            at ~/.config/git/ignore and ~/.config/fd/ignore.

            Refer to \`man gitignore\` for the syntax to use in these files, which is
            roughly the extended glob syntax that includes '**'.

            Also refer to my ~/.config/fd/ignore file, which generally excludes the
            ignore files themselves, the contents of .git dirs, and other hidden files
            of little interest.

          + Use --no-ignore-vcs to show results that would be excluded by the git-ignore
            files: .gitignore, .git/info/exclude, and ~/.config/git/ignore.

      - Further filter search results using these options:

          + -E (--exclude) pattern, which takes a glob pattern.

          + -t (--type) filetype, e.g. d for dirs, f for files, l for symlinks, x for
            executable files, or e for empty files. E.g. '-te -td' for empty dirs.

          + -e (--extension) ext, to filter by file extension. To match files with no
            extension, use the regular pattern '^[^.]+$'.

          + Time-based options, such as --newer, --older, --changed-within,
            --changed-after, --changed-before, which take a duration (e.g. 10h, 1d,
            35min) or a specific date or time (e.g. YYYY-MM-DD).

          + Other properties such as -S (--size) and -o (--owner) [user][:group].

      - The output is colorized using LS_COLORS.

          + Use -l (--list-details) to print a detailed listing, like 'ls -l'.

          + Use -0, (--print0) to use a null character between search results.

          + Use --format for custom output.

      - Use -x (--exec) command [args...] to execute a command for each result, using
        parallelized search and execution. To execute the command once, with all results
        as arguments, use -X (--exec-batch).

    Examples

      - Match all files in a directory:

        fd -HI . dir/

      - Equivalent to \"find * -name '*.txt'\":

        fd -e .txt

      - Show the disk usage of all Trash, .Trash, and .Trash-1000 folders:

        fd -H '^(\\.)?Trash(-[0-9]+)?' ~/ \\
            -X du -hsc | sort -h
    "
    [[ ${1-} == @(-h|--help) ]] &&
        { docsh -TD; return; }

    local fd_cmd
    fd_cmd=$( type -P fd ) \
        || fd_cmd=$( type -P fdfind ) \
            || return

    "$fd_cmd" --no-ignore-vcs "$@"
}
