# DCM2NII (dcm2niix, Rorden's tool)
d2n() {

    : "dcm2niix wrapper

    Calls dcm2niix with my usual settings on dicoms found in the passed dir

      - Recursively checks 5 levels of depth for dicoms by default
      - If no dir supplied, uses the current directory
      - NIfTI files are output in the current working directory
      - Additional options may be supplied, as long as the search dir is the last argument
    "

    [[ -n ${1-} ]] ||
        set -- '.'

    dcm2niix -o '.' -z 'y' -b 'y' -f '%d' "$@"
}
