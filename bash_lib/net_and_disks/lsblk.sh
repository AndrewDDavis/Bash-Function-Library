## Block Devices: lsblk
# - set display columns and no loop devices
alias lsblkx='lsblk -e 7 -o NAME,RM,VENDOR,SIZE,PTTYPE,PARTFLAGS,FSTYPE,LABEL,MOUNTPOINT'
