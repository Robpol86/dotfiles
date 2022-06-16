#!/usr/bin/env bash

# Install dotfiles and changes shell to zsh.
#
# For use with GitHub Codespaces as well as local development machines.

set -o errexit  # Exit script if a command fails.
set -o nounset  # Treat unset variables as errors and exit immediately.
set -o pipefail  # Exit script if pipes fail instead of just the last program.

CODESPACES="${CODESPACES:-}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSH="${ZSH:-"$HOME/.oh-my-zsh"}"
ZSH_CUSTOM="${ZSH_CUSTOM:-"$ZSH/custom"}"

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

# Verify source path exists and then symlink it to the target path.
symlink() {
    test -e "$1" || errex "File not found: $1"
    ln -fsv "$1" "$2"
}

# Main function.
main() {
    command -v zsh || command "$_"  # Print error if zsh command not found.
    if [ ! -e "$ZSH" ]; then
        info Installing Oh My Zsh
        RUNZSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    elif [ -n "$CODESPACES" ]; then
        info Setting codespace shell to Zsh
        sudo chsh -s "$(command -v zsh)"
    else
        info Setting shell to Zsh
        chsh -s "$(command -v zsh)"
    fi
    set -o xtrace  # Print commands before executing them.

    info Installing Zsh plugins
    git -C "$ZSH_CUSTOM/plugins" clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git
    git -C "$ZSH_CUSTOM/plugins" clone --depth=1 https://github.com/so-fancy/diff-so-fancy.git  # Not really a zsh plugin.
    symlink "$HERE/themes/robpol86.zsh-theme" "$ZSH_CUSTOM/themes/robpol86.zsh-theme"

    info Symlinking dotfiles
    symlink "$HERE/vimrc" "$HOME/.vimrc"
    symlink "$HERE/zshrc.sh" "$HOME/.zshrc"
    symlink "$HERE/zprofile.sh" "$HOME/.zprofile"

    info Install SSH config
    install -m0700 -d "$HOME/.ssh"
    symlink "$HERE/ssh_config" "$HOME/.ssh/config"

    info Execute run-once commands
    zsh -lc _robpol86_run_once
}

# Main.
main

# Success.
info Success
