# Eget: Easily install prebuilt binaries from GitHub

# TODO:
# - check command, to see if an update is available

egetx() (
    docstr="Wrapper for common operations using eget.

    Usage

      init <name> <target>
        : Initialize directory for new software at /usr/local/share/<name>, and add an
          entry to ~/.config/eget/eget.toml. The target can be a URL or github dev and
          project, like zyedidia/eget.

      ug <name> (TODO: NOT FINISHED)
        : Install or upgrade program. Downloads a new versioned binary, installs it into
          /usr/local/bin, and updates the program's symlink. If name is "all", runs the
          -D operation to download all software listed in the config file. (?)

    For all eget options, see 'eget --help', or https://github.com/zyedidia/eget.
    Briefly:

    ...

    "

    [[ $# -eq 0 || $1 == @(-h|--help) ]] && {
        docsh -TD "$docstr"
        return 0
    }

    # eget config file
    eget_conf_fn=~/.config/eget/eget.toml
    [[ ! -e $eget_conf_fn ]] && {
        echo "config file not found: $eget_conf_fn"
        return 2
    }

    # parse args
    cmd=$1
    sw_name=$2
    shift 2

    # sw dir
    sw_dir=/usr/local/share/$sw_name
    url_fn=$sw_dir/eget_url.txt

    case $cmd in
        ( init )
            url=$1

            # create dir and URL file
            mkdir -p "$sw_dir"

            [[ -e $url_fn ]] && {
                echo "url file exists: $url_fn"
                return 2
            }
            printf '%s\n' "$url" > "$url_fn"

            grep -q "$url" "$eget_conf_fn" && {
                echo "target '$url' entry exists in $eget_conf_fn"
                return 2
            }
            printf '\n["%s"]\n' "$url" >> "$eget_conf_fn"
            printf '    target = "%s"\n' "$sw_dir" >> "$eget_conf_fn"
        ;;
        ( ug )
            builtin cd "$sw_dir"
            eget -d $(< eget_url.txt)

            echo "needs implementation"
            # select system?
            # rename
            # move to bin
        ;;
    esac
)
