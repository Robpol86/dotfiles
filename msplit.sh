#!/usr/bin/env bash

# Split any video file based on timestamps.

set -e  # Exit script if a command fails.
set -o pipefail  # Exit script if pipes fail instead of just the last program.
set -u  # Treat unset variables as errors and exit immediately.
shopt -s expand_aliases  # Enable the use of aliases.

# Boilerplate variables/aliases.
BASENAME="$(basename "${BASH_SOURCE[0]}")"
SUMMARY="$(grep -Pom1 '(?<=^# )\w+.*' "${BASH_SOURCE[0]}")"
date -ud@$SECONDS &> /dev/null && alias ts='date -ud@$SECONDS +%T' || alias ts='date -ur$SECONDS +%T'

# General variables/aliases.
declare -a TIMESTAMPS=()  # Array of floats representing seconds to split on.
KEYFRAME_FORWARD_SEARCH=10.0  # How far ahead of the requested timestamp to search for keyframes.

# CLI variables.
FILE_PATH=  # Path to source file to split.
SHOW=  # Show last split file in Finder after splitting.

# Print error to stderr and exit 1.
error() {
    printf -- "\\033[31m=> $(ts) ERROR: %s\\033[0m\\n" "$*" >&2
    exit 1
}

# Print normal messages to stdout.
info() {
    printf -- "\\033[36m=> $(ts) INFO: %s\\033[0m\\n" "$*"
}

# Print usage to stdout. If $1 is anything print long usage, else only short usage.
usage() {
    echo -e "\\nUsage: $BASENAME FILE_PATH TIMESTAMP...\\n\\n$SUMMARY"
    if [ $# -gt 0 ]; then
        local _="$1"  # Linting.
        echo
        echo 'FILE_PATH is the path to the file to split.'
        echo 'TIMESTAMP is one or more timestamps (00:00 or 000 seconds) to split by. msplit'
        echo 'will actually split on the next keyframe if a timestamp is not exactly on one.'
        echo -e "\\nOptions:"
        echo '  -s, --show      Show the last split file in Finder after splitting.'
    fi
}

# Print error message and exit upon bad arguments.
bad_args() {
    echo "'$BASENAME' requires at least 2 arguments."
    echo "See '$BASENAME --help'."
    usage
    exit 2
}

# Read command line arguments.
while [ $# -gt 0 ]; do
    [[ "$1" == "-h" || "$1" == "--help" ]] && usage long && exit 2
    [[ "$1" == "--" ]] && shift && continue  # Ignore.
    if [[ "$1" == "-s" || "$1" == "--show" ]]; then
        SHOW=true; shift
    elif [ -z "$FILE_PATH" ]; then
        [ -f "$1" ] || error "No such file: $1"
        FILE_PATH="$1"; shift
    elif [[ "$1" =~ ^([0-9]+):([0-9]{1,2}):([0-9]{1,2}([.][0-9]+)?)$ ]]; then
        TIMESTAMPS+=("$(bc <<< "$(( BASH_REMATCH[1] * 3600 + BASH_REMATCH[2] * 60 )) + ${BASH_REMATCH[3]}")"); shift
    elif [[ "$1" =~ ^([0-9]+):([0-9]{1,2}([.][0-9]+)?)$ ]]; then
        TIMESTAMPS+=("$(bc <<< "$(( BASH_REMATCH[1] * 60 )) + ${BASH_REMATCH[2]}")"); shift
    elif [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        TIMESTAMPS+=("$(bc <<< "${BASH_REMATCH[0]}")"); shift
    else
        error "Invalid timestamp. Must be a float, 0:00.0, or 0:00:00.0"
    fi
done
[ ${#TIMESTAMPS[@]} -ne 0 ] || bad_args

# Probe file for metadata. Verifies highest timestamp.
probe_file() {
    local duration; duration=$(
        ffprobe -v error -select_streams v:0 -show_entries format=duration "$FILE_PATH" |grep -Pom1 '(?<=duration=)\d+'
    )
    if (( $(bc <<< "${TIMESTAMPS[${#TIMESTAMPS[@]}-1]} >= $duration") )); then
        error "Bad timestamp, file is $duration seconds long."
    fi
}

# Find nearest keyframe on or after the timestamp to split on.
next_keyframe() {
    local timestamp; timestamp="$1"

    # Find all keyframes within range. Fail if no keyframes found.
    local search_end; search_end="$(bc <<< "$timestamp + $KEYFRAME_FORWARD_SEARCH")"
    local -a keyframes; keyframes=($(
        ffprobe -read_intervals "$timestamp%$search_end" "$FILE_PATH" -select_streams v:0 -show_entries \
            frame=key_frame,pkt_pts_time -of csv=print_section=0 -hide_banner 2>/dev/null |grep -Po '(?<=^1,)[0-9.]+$'
    ))
    [ ${#keyframes[@]} -ne 0 ] || error "No keyframes between $(hms "$timestamp") and $(hms "$search_end")"

    # Return next keyframe greater than or equal to input timestamp. ffprobe sometimes goes back in time, ugh!
    local keyframe
    for keyframe in "${keyframes[@]}"; do
        if (( $(bc <<< "$keyframe >= $timestamp") )); then
            printf %.4f "$keyframe"
            return
        fi
    done

    error "No keyframes at or after $(hms "$timestamp")"
}

# Convert seconds into HH:MM:SS.
hms() {
    date -ud@$SECONDS &> /dev/null && date -ud@"${1%.*}" "+%T${1/*./.}" || date -ur"${1%.*}" "+%T${1/*./.}"
}

# Sort/unique timestamps and adjust each to the next keyframe.
update_timestamps() {
    # Sort timestamps and remove duplicates.
    IFS=$'\n' TIMESTAMPS=($(sort -un <<< "${TIMESTAMPS[*]}"))
    unset IFS

    # Verify greatest timestamp.
    probe_file

    # Apply precision to all timestamps.
    local -i i
    for i in "${!TIMESTAMPS[@]}"; do
        TIMESTAMPS[${i}]="$(printf %.4f "${TIMESTAMPS[$i]}")"
    done

    # Keyframes.
    local difference
    local timestamp
    info "Adjusting timestamps to keyframes..."
    for i in "${!TIMESTAMPS[@]}"; do
        timestamp="$(next_keyframe "${TIMESTAMPS[$i]}")"
        difference=$(printf %.4f "$(bc <<< "$timestamp - ${TIMESTAMPS[$i]}")")
        [[ ${difference} =~ ^- ]] || difference="+$difference"
        info "$(hms "${TIMESTAMPS[$i]}") -> $(hms "$timestamp") ($difference)"
        TIMESTAMPS[${i}]="$timestamp"
    done
}

# Split the file into multiple files.
do_split() {
    local times; times="$(IFS=,; echo "${TIMESTAMPS[*]}")"
    local -i count; count=$(( ${#TIMESTAMPS[@]} + 1 ))

    # Determine destination path.
    local dst_path
    if [[ "${FILE_PATH##*/}" =~ ^[0-9]{4}[[:blank:]]-[[:blank:]][A-Za-z0-9]{3,5}[[:blank:]]-[[:blank:]].*[[:blank:]]-[[:blank:]].*\..{1,4}$ ]]; then
        dst_path="${FILE_PATH% - *} (Clip %0${#count}d) - ${FILE_PATH##* - }"
    else
        dst_path="${FILE_PATH%.*} (Clip %0${#count}d).${FILE_PATH##*.}"
    fi

    # Run ffmpeg.
    info "Splitting $FILE_PATH into $count files"
    (
        set -x
        ffmpeg -i "$FILE_PATH" -c copy -map_metadata 0 \
            -f segment -reset_timestamps 1 -segment_start_number 1 -segment_times "$times" "$dst_path"
    )

    # Show file in Finder.
    [ -z "$SHOW" ] || open -R "$dst_path"
}

# Run.
update_timestamps
do_split
info Done.
