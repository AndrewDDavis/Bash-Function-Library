# tree lists files, accepting an optional pattern
# Notable options:
#   -a : print all files, including dot-files
#   -d : print only directories
#   -s : print sizes
#   -h : human-readable sizes
#   -D : print dates
#   -p : print permissions
#   -F : print file-type indicator (/, =, *, ...)
#   -L : max depth of tree listing (CWD = 1)
#   --dirsfirst : meta-sort directories before files
#   --du : report directory sizes as disk usage of contents

# quick aliases, as for ls
alias tt='tree --filesfirst'
alias tta='tt -a'
alias ttd='tt -d'
alias tts='tt -sh'
alias ttad='tt -ad'
alias ttas='tt -ash'
alias ttl2='tt -L2'
