#!/usr/bin/env sh

# Usage: open.sh [-R] FILE_DIR_OR_LINK
#
# Run "open -R ..." to reveal the file in explorer instead of opening it.

set -e  # Exit script if a command fails.
set -u  # Treat unset variables as errors and exit immediately.

usage() {
    echo "Usage: open.sh [-R] FILE_DIR_OR_LINK" >&2
    exit 2
}

# Handle -R.
case ${1:-} in
    -R|-r)
        REVEAL=true
        shift
        ;;
    *)
        REVEAL=
esac

# Usage on no arguments.
if [ $# -eq 0 ]; then
    usage
fi

# # Get file path.
# FILE_OR_DIR_PATH="$(realpath "$*")"
# if [ ! -e "$FILE_OR_DIR_PATH" ]; then
#     echo "No such file: $FILE_OR_DIR_PATH" >&2
#     exit 1
# fi

# # Determine mount path outside of WSL.
# MOUNT="$(stat -c %m "$FILE_OR_DIR_PATH")"
# FOD_TRUNCATED="${FILE_OR_DIR_PATH:${#MOUNT}}"
# WIN_ROOT="$(findmnt -n -o SOURCE "$MOUNT")"
# FOD_WIN_PATH="${WIN_ROOT%\\}${FOD_TRUNCATED//\//\\}"

# # Open.
# /mnt/c/Windows/explorer.exe ${SELECT:+/select,} "$FOD_WIN_PATH"
