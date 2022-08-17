#!/usr/bin/env sh

# Usage: open [-R] FILE_DIR_OR_LINK
#
# Run "open -R ..." to reveal the file in explorer instead of opening it.

set -e  # Exit script if a command fails.
set -u  # Treat unset variables as errors and exit immediately.

usage() {
    echo "Usage: open [-R] FILE_DIR_OR_LINK" >&2
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

# Reveal in explorer.
if [ "$REVEAL" = true ]; then
    windows_path="$(wslpath -w "$*")"
    /mnt/c/Windows/explorer.exe "/select," "$windows_path"
    exit 0
fi

# Open file/link with https://github.com/wslutilities/wslu.
wslview "$*"
