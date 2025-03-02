# Research Software Tools

# AFNI
if [[ -d /usr/local/afni/bin ]]
then
    # manual binary install on macOS and Linux from https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/background_install/main_toc.html
    path_check_add '/usr/local/afni/bin'
    [[ $(uname -s) == "Darwin" ]] && export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH}:/opt/X11/lib/flat_namespace"

    # command-line tab-completion of options (time consuming, only uncomment if you'd use it)
    # [[ -f "$(apsearch -afni_help_dir)"/all_progs.COMP.bash ]] && source "$(apsearch -afni_help_dir)"/all_progs.COMP.bash

elif [[ -e /etc/afni/afni.sh ]]
then
    # neurodebian install
    source /etc/afni/afni.sh
fi

# ANTs Advanced Normalization Tools
[[ -d /usr/local/ants ]] && { export ANTSPATH=/usr/local/ants/bin/
                              path_check_add '/usr/local/ants/bin'
                              export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=2; }

# Camino DTI package
if [[ -d /usr/local/camino ]]
then
    path_check_add '/usr/local/camino/bin'
    # export MANPATH="/usr/local/camino/man:${MANPATH}"  # not necessary, would be picked up automatically
    export CAMINO_HEAP_SIZE=4096
    export CAMINODIR=/usr/local/camino
fi

# Connectome Workbench
path_check_add -b '/usr/local/connectome_workbench'

# Convert3D Medical Image Processing Tool
path_check_add '/usr/local/c3d/bin'

# DCM2NII (dcm2niix, Rorden's tool)
d2n () {
    # Calls dcm2niix with my usual settings on dicoms found in the passed dir
    # - Recursively checks 5 levels of depth for dicoms by default
    # - If no dir supplied, uses the current directory
    # - NIfTI files are output in the current working directory
    # - Additional options may be supplied, as long as the search dir is the last argument
    [[ -z ${1:-} ]] && set - '.'

    dcm2niix -o '.' -z 'y' -b 'y' -f '%d' "$@"
}

# dcm2nii
[[ $( uname -s ) == Linux && -n $( command -v dcm2nii ) ]] && {
    alias dcm2nii="dcm2nii-linux"
}

# DCMTK -- Does this still exist?
path_check_add '/usr/local/dcmtk/bin'

# Dicom Browser
path_check_add -b '/usr/local/DicomBrowser-1.5.2/bin'

# Diffusion Toolkit and TrackVis
path_check_add -b -o '/Applications/Diffusion Toolkit.app/Contents/MacOS' \
                     '/usr/local/trackvis'
path_check_add -b -o '/Applications/TrackVis.app/Contents/MacOS' \
                     '/usr/local/dtk'

# DTI-TK
if [[ -d /usr/local/dtitk/bin ]]
then
    path_check_add -b '/usr/local/dtitk/bin' '/usr/local/dtitk/scripts'
    export DTITK_ROOT=/usr/local/dtitk
fi

# Fiji/ImageJ
[[ -d /Applications/Fiji.app/Contents/MacOS/ ]] && \
	alias fiji="/Applications/Fiji.app/Contents/MacOS/ImageJ-macosx"

# FreeSurfer
if [[ -d /usr/local/freesurfer ]] || [[ -d /Applications/freesurfer ]]
then
    if [[ -d /usr/local/freesurfer ]]
    then
        export FREESURFER_HOME=/usr/local/freesurfer
    elif [[ -d /Applications/freesurfer ]]
    then
        export FREESURFER_HOME=/Applications/freesurfer
    fi

    export FS_FREESURFERENV_NO_OUTPUT=True
    source "$FREESURFER_HOME"/SetUpFreeSurfer.sh
    unset d os output # annoying FS variables persist
fi

# FSL setup
# - put this after Freesurfer or else PATH will be duplicated
if [[ -d /usr/local/fsl ]]
then
    export FSLDIR=/usr/local/fsl

elif [[ -d /usr/share/fsl/5.0 ]]
then
    export FSLDIR=/usr/share/fsl/5.0
fi

[[ -n ${FSLDIR:-} ]] && {

    path_check_add "$FSLDIR/bin"
    source "$FSLDIR/etc/fslconf/fsl.sh"

    [[ -d /Applications/FSLeyes.app ]]  \
        && alias fsleyes_app="/Applications/FSLeyes.app/Contents/MacOS/fsleyes"
}

# FSL from neurodebian
#if [[ -x /usr/bin/fsl4.1-mcflirt ]]; then
#   for fslx in /usr/bin/fsl4.1-*; do
#      alias ${fslx##/usr/bin/fsl4.1-}=${fslx}
#   done
#elif [[ -x /usr/bin/fsl5.0-mcflirt ]]; then
#   for fslx in /usr/bin/fsl5.0-*; do
#      alias ${fslx##/usr/bin/fsl5.0-}=${fslx}
#   done
#fi

# FSLview as single
#alias fslview="fslview -m single"

# ITK-SNAP
path_check_add '/usr/local/itksnap/bin/'

# Mango image viewer
path_check_add -b '/usr/local/Mango/utils'

# Matlab
# - prefer newest version
# - macOS uses /Applications, Linux uses /usr/local
path_check_add -o '/Applications/MATLAB_R2019b.app/bin'  \
                  '/Applications/MATLAB_R2017b.app/bin'  \
                  '/Applications/MATLAB_R2016b.app/bin'  \
                  '/Applications/MATLAB_R2014a.app/bin'  \
                  '/usr/local/MATLAB/R2018a/bin'         \
                  '/usr/local/MATLAB/R2012a/bin'

alias matlabs='matlab -nodisplay -nosplash'
alias matlabr='matlab -r'
[ -e /Applications/MATLAB_R2014a.app/bin/matlab ] \
    && alias matlab14='MATLAB_JAVA=/Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin/Contents/Home /Applications/MATLAB_R2014a.app/bin/matlab'

#MATLAB Compiler Runtime config
# note these caused problems for running other commands -- commenting unless I need to run the runtime
# if [[ -d /usr/local/MATLAB/MATLAB_Compiler_Runtime ]]
# then
#     export XAPPLRESDIR=/usr/local/MATLAB/MATLAB_Compiler_Runtime/v717/X11/app-defaults
#     export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}${LD_LIBRARY_PATH:+:}/usr/local/MATLAB/MATLAB_Compiler_Runtime/v717/runtime/glnxa64:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v717/bin/glnxa64:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v717/sys/os/glnxa64:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v717/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v717/sys/java/jre/glnxa64/jre/lib/amd64/server:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v717/sys/java/jre/glnxa64/jre/lib/amd64
# fi

# MRIcroGL
path_check_add -b /usr/local/MRIcroGL

# MRTrix -- compiled or homebrew
if [[ -d /usr/local/mrtrix3 ]]
then
    path_check_add '/usr/local/mrtrix3/bin'
    export MRTRIXDIR=/usr/local/mrtrix3

elif [[ -x /usr/local/bin/dwidenoise ]]
then
    export MRTRIXDIR=/usr/local
fi

# Nipype
[[ -d /usr/local/MATLAB/R2012a ]] && export MATLABCMD=/usr/local/MATLAB/R2012a/bin/glnxa64/MATLAB

# Read GE files
alias rdgehdr="rdgehdr-mac"

# Slicer
path_check_add '/usr/local/Slicer-4.3.1-linux-amd64'
