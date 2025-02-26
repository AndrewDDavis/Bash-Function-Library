# Forked from https://github.com/officialrajdeepsingh/nerd-fonts-installer
# just import this file, then run the function

nerd-fonts-install() {

    local rmt_cmd font_list font_name font_url fonts_dir=~/.local/share/fonts

    # Check for curl or wget and unzip
    if [[ -n $( command -v curl ) ]]
    then
        rmt_cmd=( curl -fLO )

    elif [[ -n $( command -v wget ) ]]
    then
        rmt_cmd=( wget )

    else
        err_msg 2 "Couldn't find curl or wget on PATH."
        return 2
    fi

    [[ -n $( command -v unzip ) ]] || {
        err_msg 2 "Couldn't find unzip on PATH."
        return 2
    }

    font_list=( "Agave"  "AnonymousPro"  "Arimo"  "AurulentSansMono"
                "BigBlueTerminal"  "BitstreamVeraSansMono"
                "CascadiaCode"  "CodeNewRoman" "ComicShannsMono"  "Cousine"
                "DaddyTimeMono"  "DejaVuSansMono"
                "FantasqueSansMono"  "FiraCode"  "FiraMono"
                "Gohu"  "Go-Mono"
                "Hack"  "Hasklig"  "HeavyData"  "Hermit"
                "iA-Writer"  "IBMPlexMono"  "InconsolataGo"  "InconsolataLGC"  "Inconsolata"  "IosevkaTerm"
                "JetBrainsMono"
                "Lekton"  "LiberationMono"  "Lilex"
                "Meslo"  "Monofur"  "Monoid"  "Mononoki"  "MPlus"
                "NerdFontsSymbolsOnly"  "Noto"
                "OpenDyslexic"  "Overpass"
                "ProFont"  "ProggyClean"
                "RobotoMono"
                "ShareTechMono"  "SourceCodePro"  "SpaceMono"
                "Terminus"  "Tinos"
                "UbuntuMono"  "Ubuntu"
                "VictorMono"
    )

    # Main

    (
    # ensure alignment
    tabs -8
    COLUMNS=80

    PS3="Select Font by number: "

    select font_name in "${font_list[@]}" "Quit"
    do

        if [ -n "$font_name" ]
        then

            [[ $font_name == Quit ]] && return

            # Check for fonts dir
            [[ -d $fonts_dir ]] || {
                echo "creating $fonts_dir"
                mkdir -p "$fonts_dir"
            }

            if [[ -e $fonts_dir/$font_name ]]
            then
                echo "path exists: $fonts_dir/$font_name"
                echo "skipping..."

            else
                # download
                font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font_name.zip"
                cd /tmp
                "${rmt_cmd[@]}" "$font_url" || return

                # install
                mkdir "$fonts_dir/$font_name"
                unzip "$font_name.zip" -d "$fonts_dir/$font_name/"
                fc-cache -fv

                # clean up
                rm ./"$font_name.zip"
                cd -
                echo "done."
            fi
        else

            echo "Select a valid font by number"
            continue
        fi
    done
    )
}
