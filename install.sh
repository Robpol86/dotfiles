#!/usr/bin/env bash

# Usage: PROGRAM [OPTIONS] POS_ARGS_1 POS_ARGS_2
#
# Boilerplate example bash script.
#
# Long description goes here. Usually you explain what each of the positional
# arguments do.
#
# Options:
#   -a          A boolean command line switch. This also has a long description
#               that wraps to the next line after 80 characters.
#   -c num      Exit prematurely with this error code.
#   -d          Enable debug logging.
#   -e          Print error and exit.
#   -E          Simulate unhandled error (tests set -e).
#   -h          Display this help.
#   -H value    A string command line switch (must have value) (default: default).
#   -U          Simulate unhandled error (tests set -u).

set -o errexit  # Exit script if a command fails.
set -o nounset  # Treat unset variables as errors and exit immediately.
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

# Print error message and exit upon bad arguments.
bad_arg() {
    local program; program="$(basename "${BASH_SOURCE[0]}")"
    if [ $# -gt 0 ]; then
        echo "$1"
        echo "See '$program -h'."
    else
        echo "'$program' requires exactly 2 arguments."
        echo "See '$program -h'."
        cd "$(dirname "${BASH_SOURCE[0]}")"  # It's OK to change directory since we'll exit 1 in this function.
        awk '/^# Usage: /{i=3;sub(/PROGRAM/,FILENAME);print ""};i{print substr($0,3);i--}' "$program"
    fi
    exit 1
}

# Validate getopts $OPTARG against regex.
validate_re() {
    local pattern="$1"
    local value
    if [ $# -gt 1 ]; then
        value="$2"
    else
        value="$OPTARG"
    fi
    [[ "$value" =~ $pattern ]] || errex "Invalid input ($pattern): $value"
}

# Main function.
main() {
    # Print variables.
    info "ERROR: $ERROR"
    info "FLAG_A: $FLAG_A"
    info "FLAG_H: $FLAG_H"
    warning "POS_ARGS_1: $POS_ARGS_1"
    warning "POS_ARGS_2: $POS_ARGS_2"
    if [ "$ERROR" == true ]; then
        sleep 1
        errex Sample Error
    fi

    # Premature exit code.
    if [ -n "$EXIT_CODE" ]; then
        warning "Exiting early with code: $EXIT_CODE"
        exit "$EXIT_CODE"
    fi

    # Unhandled error tests.
    if [ "$SET_E" == true ]; then
        warning Testing set -e shell option.
        ls /does_not_exist
        echo Unreachable
    fi
    if [ "$SET_U" == true ]; then
        warning Testing set -u shell option.
        : "$DOES_NOT_EXIST"
        echo Unreachable
    fi

    # Debug argument usecase.
    info "Testing DEBUG..."
    local tmpdir; tmpdir="$(mktemp -d)"
    tee "$tmpdir/src.txt" <<< "dummy string"
    cp ${DEBUG:+-v} "$tmpdir/src.txt" "$tmpdir/dst.txt"
    rm -r "$tmpdir"
}

# Parse command line arguments.
declare -a OPTPOS=()
while [ $# -gt 0 ]; do
    unset OPT OPTARG OPTERR OPTIND OPTLAST; while getopts :ac:deEhH:U OPT; do
        case "$OPT" in
            \?) bad_arg "unknown flag: '$OPTARG'" ;;
            :) bad_arg "flag needs an argument: '$OPTARG'" ;;
            a) FLAG_A=true ;;
            c) validate_re '^[0-9]+$'; EXIT_CODE="$OPTARG" ;;
            d) DEBUG=true ;;
            e) ERROR=true ;;
            E) SET_E=true ;;
            h) cd "$(dirname "${BASH_SOURCE[0]}")"  # It's OK to change directory since we'll exit 0 in this case.
               program="$(basename "${BASH_SOURCE[0]}")"
               awk '/^# Usage: /{i=1;sub(/PROGRAM/,FILENAME);print ""};!/^#/{if(i)exit};i{print substr($0,3)}' "$program"
               exit 0 ;;
            H) FLAG_H="$OPTARG" ;;
            U) SET_U=true ;;
        esac
    done; OPTLAST="${*:OPTIND-1:1}"; shift "$((OPTIND-1))"
    while [ $# -gt 0 ]; do OPTPOS+=("$1"); shift; [ "$OPTLAST" == "--" ] || break; done
done
[ "${#OPTPOS[@]}" -eq 2 ] || bad_arg
POS_ARGS_1="${OPTPOS[0]}"
POS_ARGS_2="${OPTPOS[1]}"
unset OPTPOS

# Print message on failure.
[ "${BASH_VERSINFO[0]}" -le 3 ] || trap 'test 0 -eq $? || ( (errex Failure) || exit $_)' EXIT

# Implement debug flag.
if [ "$DEBUG" == true ]; then
    set -o xtrace  # Print commands before executing them.
fi

# Main.
main

# Success.
info Success
