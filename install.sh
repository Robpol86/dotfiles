#!/usr/bin/env bash

# Boilerplate example bash script.
#
# Long description goes here. Usually you explain what each of the positional
# arguments do.

set -o errexit  # Exit script if a command fails.
set -o nounset  # Treat unset variables as errors and exit immediately.
set -o xtrace  # Print commands before executing them.
set -o pipefail  # Exit script if pipes fail instead of just the last program.

FLAG_A=false  # true if user specifies -a.
EXIT_CODE=""  # Switch value if user specifies -c <value>.
DEBUG=  # true if user specifies -d.
ERROR=false  # true if user specifies -e.
SET_E=false  # true if user specifies -E.
FLAG_H=default  # Switch value if user specifies -H <value>.
SET_U=false  # true if user specifies -U.
POS_ARGS_1=  # Value of first positional argument.
POS_ARGS_2=  # Value of second positional argument.

# Print error to stderr.
error() {
    printf '\e[31m=> %02d:%02d:%02d ERROR: %s\e[0m\n' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60)) "$*" >&2
}

# Print error to stderr and exit 1.
errex() {
    error "$*"
    exit 1
}

# Print warning to stderr.
warning() {
    printf '\e[33m=> %02d:%02d:%02d WARNING: %s\e[0m\n' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60)) "$*" >&2
}

# Print normal messages to stdout.
info() {
    printf '\e[36m=> %02d:%02d:%02d INFO: %s\e[0m\n' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60)) "$*"
}

# Main function.
main() {
    # Verify ZSH is installed.
    which zsh

    # Install Oh My Zsh.
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    # TODO.
}

# Main.
main

# Success.
info Success
