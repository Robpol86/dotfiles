#!/usr/bin/env bash

# Install dotfiles and changes shell to zsh.
#
# For use with GitHub Codespaces as well as local development machines.

set -o errexit  # Exit script if a command fails.
set -o nounset  # Treat unset variables as errors and exit immediately.
set -o pipefail  # Exit script if pipes fail instead of just the last program.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
    info Installing Oh My Zsh
    RUNZSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    set -o xtrace  # Print commands before executing them.

    info Installing Zsh plugins
    ZSH_CUSTOM="${ZSH_CUSTOM:-"$HOME/.oh-my-zsh/custom"}"
    git -C "$ZSH_CUSTOM/plugins" clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git
    git -C "$ZSH_CUSTOM/plugins" clone --depth=1 https://github.com/so-fancy/diff-so-fancy.git  # Not really a zsh plugin.
    ln -fsv {"$HERE","$ZSH_CUSTOM"}/themes/robpol86.zsh-theme
    ln -fsv {"$HERE","$ZSH_CUSTOM"}/themes/robpol86.zsh-theme-bad
}

# Main.
main

# Success.
info Success
