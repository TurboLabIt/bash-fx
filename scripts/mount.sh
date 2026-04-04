function fxMountBind()
{
  fxTitle "Bind-mounting folder ##$1## to ##$2##"

  local SOURCE_DIR="$1"
  local TARGET_DIR="${2%/}/"

  if [ -z "$SOURCE_DIR" ]; then
    fxCatastrophicError "No source folder provided"
  fi

  if [ -z "$2" ]; then
    fxCatastrophicError "No target mountpoint provided"
  fi

  sudo mkdir -p "$TARGET_DIR"
  sudo umount "$TARGET_DIR"
  sudo touch "${TARGET_DIR}This is the mountpoint. The target directory is UNMOUNTED"

  local MOUNT_OUTPUT
  MOUNT_OUTPUT=$(sudo mount --bind "$SOURCE_DIR" "$TARGET_DIR" 2>&1)

  if [[ $? -eq 0 ]]; then

    fxOK "Folder bind-mounted to ##$TARGET_DIR##"

  else

    fxCatastrophicError "Unable to mount the folder: $MOUNT_OUTPUT"
  fi

  echo ""
  ls -l --color=always "${TARGET_DIR}"
}


function fxMountVmwareShare()
{
  fxTitle "Mounting VMware shared folder ##$1##"

  if [ -z "$1" ]; then
    fxCatastrophicError "Error: No folder name provided."
  fi

  local FOLDER_NAME="$1"
  local MOUNTPOINT_DIR="/mnt/hgfs/${1,,}/"

  sudo mkdir -p "$MOUNTPOINT_DIR"
  sudo umount "$MOUNTPOINT_DIR"
  sudo touch "${MOUNTPOINT_DIR}This is the VM disk. The host dir is UNMOUNTED"

  local MOUNT_OUTPUT
  MOUNT_OUTPUT=$(sudo vmhgfs-fuse ".host:/$FOLDER_NAME" "${MOUNTPOINT_DIR}" -o allow_other 2>&1)

  if [[ $? -eq 0 ]]; then

    fxOK "Folder mounted to ##$MOUNTPOINT_DIR##"

  else

    fxCatastrophicError "Unable to mount the folder: $MOUNT_OUTPUT"
  fi

  echo ""
  ls -l --color=always "${MOUNTPOINT_DIR}"
}
