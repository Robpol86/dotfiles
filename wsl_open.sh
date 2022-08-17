#!/usr/bin/env sh

# Similar to macOS's open command.
#
# Usage: open [-R] FILE_DIR_OR_LINK
#        open -h
#
# Run "open -R ..." to reveal the file in explorer instead of opening it.

set -e  # Exit script if a command fails.
set -u  # Treat unset variables as errors and exit immediately.

usage() {
    echo "Usage: open [-R] FILE_DIR_OR_LINK" >&2
    echo "       open -h" >&2
    echo 'Run "open -R ..." to reveal the file in explorer instead of opening it.' >&2
    exit 2
}

# Handle -R.
case ${1:-} in
    -h)
        usage
        ;;
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
    /mnt/c/Windows/explorer.exe "/select," "$windows_path" || true  # TODO https://github.com/microsoft/WSL/issues/6565
    exit 0
fi

# Open file/link with https://github.com/wslutilities/wslu.
if windows_path="$(wslpath -w "$*" 2>/dev/null)"; then
    # Is file and it exists.
    wslview "$windows_path"
else
    # Might be link, wslview will fail if it's a file/dir that doesn't exist.
    wslview "$*"
fi
