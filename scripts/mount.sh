function fxMountVmwareShare()
{
  fxTitle "Mounting VMware shared folder ##$1##"

  if [ -z "$1" ]; then
    fxCatastrophicError "Error: No folder name provided."
  fi

  local FOLDER_NAME="$1"
  local MOUNTPOINT_DIR="/mnt/hgfs/${1,,}/"

  sudo mkdir -p "${MOUNTPOINT_DIR}"
  sudo touch "${MOUNTPOINT_DIR}This is the VM disk. The host dir is UNMOUNTED"

  local MOUNT_OUTPUT
  MOUNT_OUTPUT=$(sudo vmhgfs-fuse ".host:/$FOLDER_NAME" "${MOUNTPOINT_DIR}" -o allow_other 2>&1)

  if [[ $? -eq 0 ]]; then

    fxOK "Folder mounted to ##$MOUNTPOINT_DIR##"

  else

    fxCatastrophicError "Unable to mount the folder: $MOUNT_OUTPUT"
  fi

  ls -l --color=always "${MOUNTPOINT_DIR}"
}
