#!/bin/bash
set -euo pipefail

################################################################################################
# File: read_write_config_files.sh
# Author: Andreas
# Date: 20250826
# Purpose:
# - Read variables from file
# - Wrtie varibales to file
#
# Variable examples:
#  - github_repository=x400-backup
#  - branch_name="main"
#  - backupPaths=( \
#    "printer_data/config/*" \
#    "mainsail-config/client.cfg" \
#    )
#  - paths=("a" "b")
#
################################################################################################


######################################################
# Usage:
#   load_var <config-file> <variable-name>
#
# After calling, you'll have either:
#   - an array variable $<name> (if the config used name=( ... ))
#   - or a string variable $<name> (if the config used name=value)

## Get Variable / Arry from file
#load_var <config-file> <variable-name>
#
## Check if variable or array
#declare -p backupPaths 2>/dev/null | grep -q 'declare \-a'
#if [[ $? -eq 0 ]]; then
#    echo "backupPaths is an array"
#else
#    echo "backupPaths is a string"
#fi

load_var() {
    local conf_file="$1"
    local target_var="$2"

    if [[ -z "$conf_file" || -z "$target_var" ]]; then
        echo "Usage: load_var <config-file> <variable-name>"
        return 1
    fi
    if [[ ! -f "$conf_file" ]]; then
        echo "File not found: $conf_file"
        return 1
    fi

    local current_var=""
    local storing_array=0

    # Reset any previous temp array for the target
    unset __tmp_array__ 2>/dev/null
    declare -ag __tmp_array__=()

    while IFS= read -r raw; do
        # Strip leading/trailing spaces
        local line="${raw#"${raw%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        # Skip empty lines and full-line comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        # If we are currently collecting a multi-line array
        if (( storing_array )); then
            # End of array?
            if [[ $line =~ ^\)$ ]]; then
                storing_array=0
                current_var=""
                continue
            fi

            # Array entry (supports "..." or '...')
            if [[ $line =~ ^\"(.*)\"\s*\\?$ ]]; then
                __tmp_array__+=("${BASH_REMATCH[1]}")
                continue
            elif [[ $line =~ ^\'(.*)\'\s*\\?$ ]]; then
                __tmp_array__+=("${BASH_REMATCH[1]}")
                continue
            elif [[ -n "$line" ]]; then
              # Take unquoted token, strip trailing backslash if present
              entry="${line%\\}"
              __tmp_array__+=("$entry")
              continue
            else
                # Ignore anything else inside array block / unexpected
                continue
            fi
        fi

        # Not currently in array block: detect array start for any var
        if [[ $line =~ ^([a-zA-Z_][a-zA-Z0-9_]*)=\(\s*\\?$ ]]; then
            current_var="${BASH_REMATCH[1]}"
            if [[ $current_var == "$target_var" ]]; then
                storing_array=1
                __tmp_array__=()
            fi
            continue
        fi

        # One-line array variant: var=( "a" "b" )
        if [[ $line =~ ^([a-zA-Z_][a-zA-Z0-9_]*)=\(\s*(.*)\s*\)$ ]]; then
            local varname="${BASH_REMATCH[1]}"
            local inner="${BASH_REMATCH[2]}"
            if [[ $varname == "$target_var" ]]; then
                __tmp_array__=()
                # Parse quoted tokens only: "..." or '...'
                # (Unquoted tokens are ignored to avoid unsafe eval.)
                while [[ $inner =~ ^[[:space:]]*\"([^\"]*)\"[[:space:]]*(.*)$ ]]; do
                    __tmp_array__+=("${BASH_REMATCH[1]}")
                    inner="${BASH_REMATCH[2]}"
                done
                while [[ $inner =~ ^[[:space:]]*\'([^\']*)\'[[:space:]]*(.*)$ ]]; do
                    __tmp_array__+=("${BASH_REMATCH[1]}")
                    inner="${BASH_REMATCH[2]}"
                done
                # Export array to caller
                unset "$target_var" 2>/dev/null
                declare -ag "$target_var=()"
                eval "$target_var+=(\"\${__tmp_array__[@]}\")"
                unset __tmp_array__
                return 0
            fi
            continue
        fi

        # Single-line scalar assignment: var=value   or   var="value" / 'value'
        if [[ $line =~ ^([a-zA-Z_][a-zA-Z0-9_]*)=(.*)$ ]]; then
            local varname="${BASH_REMATCH[1]}"
            local val="${BASH_REMATCH[2]}"

            # Trim trailing comments when not quoted (e.g., foo=bar # note)
            if [[ ! $val =~ ^[\"\'] ]]; then
                val="${val%%#*}"
                val="${val%"${val##*[![:space:]]}"}"
            fi

            # Strip matching surrounding quotes if present
            if [[ $val =~ ^\"(.*)\"$ ]]; then
                val="${BASH_REMATCH[1]}"
            elif [[ $val =~ ^\'(.*)\'$ ]]; then
                val="${BASH_REMATCH[1]}"
            fi

            if [[ $varname == "$target_var" ]]; then
                # Define scalar in caller's scope (string, not array)
                printf -v "$target_var" '%s' "$val"
                # Ensure not accidentally an array
                declare -p "$target_var" >/dev/null 2>&1
                return 0
            fi
            continue
        fi

        # Anything else: ignore
    done < "$conf_file"

    # If we leave the loop while collecting the target array, finalize it
    if (( storing_array )) && [[ $current_var == "$target_var" ]]; then
        unset "$target_var" 2>/dev/null
        declare -ag "$target_var=()"
        eval "$target_var+=(\"\${__tmp_array__[@]}\")"
        unset __tmp_array__
        return 0
    fi

    echo "Variable '$target_var' not found in $conf_file"
    return 2
}

# --- Example usage (commented) ---
# source parse_env.sh
# load_var env.conf github_repository
# echo "repo: $github_repository"
# load_var env.conf branch_name
# echo "branch: $branch_name"
# load_var env.conf backupPaths
# declare -p backupPaths   # shows as an array
# for p in "${backupPaths[@]}"; do echo "→ $p"; done
