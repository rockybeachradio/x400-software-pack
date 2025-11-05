#!/bin/bash
set -euo pipefail

################################################################################################
# File: read_write_config_files.sh
# Author: Andreas
# Date: 20250826
# Purpose:
# - read_var_from_file() - Read variable from file
# - write_var_to_file() - Write variable to file
# - check if variable is an array or string
#
# Include this file to the calling bash script:
#   source read_write_config_files.sh      # Include shell script with the read and write function for configuration files.
#
################################################################################################
echo "This is $(basename "$0")"

################################################################################################
# How to call
################################################################################################
# How to call the read_var_from_file function
# $ read_var_from_file "<file name>" <variable name in file> [variable in which value is saved -optional]
#       If optional parameter is not given, <variable name in file> is used.
#
# ::: Example ::
#
# Variable declaration
#   local source_file="env.conf"                  # Name and path to the configuration file
#
#   local backupPaths                 # name of the variable in the source file
#   local backupPaths_from_file       # name of the variable in the script. If not given, source_var_name_in_file is used.
#
# Array -> read backupPaths from file and store it in backupPaths_from_file
#   read_var_from_file "$source_file" backupPaths backupPaths_from_file
#   print_var_info backupPaths_from_file
#
# Scalar -> read github_repository from file and store it in github_repository_from_file
#   read_var_from_file "$source_file" github_repository github_repository_from_file
#   print_var_info github_repository_from_file
#
# If the variable_name used in the file is the variable_name used to store the value(s) in.
#   read_var_from_file "$source_file" github_repository
#   print_var_info github_repository
#
######################################################
# How to call the write_var_to_file function
# $ write_var_to_file "<file name>" "<variable name in file>" <value of the variable>
#
# ::: Example ::
#
# Variables declaration
#   local destination_file=env.conf   # Name and path to the configuration file
#
#   github_token=ghp_xxxxxx
#   branch_name="main"
#   commit_email="andreas@klipper-74e8755"
#   backupPaths=( "printer_data/config/*" "mainsail-config/client.cfg" )
#   backupPaths_2=( \
#   "printer_data/config/*" \
#   "printer_data/database/" \
#   )
#
# Write variables back to destination_file
#   write_var_to_file "$destination_file" github_token
#   write_var_to_file "$destination_file" branch_name
#   write_var_to_file "$destination_file" commit_email
#   write_var_to_file "$destination_file" backupPaths   # writes as multiline block
#   write_var_to_file "$destination_file" backupPaths_2   # writes as multiline block

################################################################################################
# Helper: print type + value(s) of a variable by NAME
################################################################################################
print_var_info() {
  local name="$1"

  if ! declare -p "$name" &>/dev/null; then
    echo "variable '$name' is not set"
    return 1
  fi

  if is_array "$name"; then
    echo "type: array"
    declare -n __arr_ref="$name"
    for p in "${__arr_ref[@]}"; do
      printf '→ %s\n' "$p"
    done
  else
    echo "type: string"
    declare -n __ref="$name"
    printf '%s\n' "$__ref"
  fi
} # End of function print_var_info()

######################################################
is_array() {
  local name="$1"
  local decl
  decl="$(declare -p "$name" 2>/dev/null || true)"
  [[ "$decl" == "declare -a"* ]]
} # End of function: is_array()

################################################################################################
# Read variables/arrays from file
################################################################################################
read_var_from_file() {
  # read_var_from_file <config-file> <source-var-in-file> [dest-var-in-shell]
  # Reads the value from <source-var-in-file> in <config-file> and stores it in <dest-var-in-shell> (or same name if omitted).
  # Supports scalar variables and arrays (one-line or multi-line).
  # Sets __last_type to "array" or "string".

  local conf_file="$1"
  local source_var="$2"
  local dest_var="${3:-$2}"

  # Input validation
  if [[ -z "$conf_file" || -z "$source_var" ]]; then
    echo "Usage: read_var_from_file <config-file> <source-var> [dest-var]" >&2
    return 1
  fi
  if [[ ! -f "$conf_file" ]]; then
    echo "File not found: $conf_file" >&2
    return 1
  fi
  if [[ ! "$dest_var" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    echo "Invalid destination variable name: $dest_var" >&2
    return 1
  fi

  local current_var=""
  local storing_array=0
  local -a __tmp_array__=()
  local line raw
  __last_type=""

  while IFS= read -r raw || [[ -n "$raw" ]]; do
    # Trim whitespace
    line="${raw#"${raw%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"

    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    # Handle multi-line array parsing
    if (( storing_array )); then
      # Check for valid array end
      if [[ $line == ")" && $current_var == "$source_var" ]]; then
        if [[ ${#__tmp_array__[@]} -gt 0 ]]; then
          unset "$dest_var" 2>/dev/null || true
          declare -g -a "$dest_var"
          declare -n __dst="$dest_var"
          __dst=("${__tmp_array__[@]}")
          unset -n __dst
          __last_type="array"
          unset __tmp_array__
          return 0
        fi
        storing_array=0
        current_var=""
        continue
      elif [[ $line == ")" ]]; then
        # End of non-target array
        storing_array=0
        current_var=""
        continue
      fi

      # Parse array entries
      if [[ $line =~ ^\"(.*)\"\s*\\?$ ]]; then
        __tmp_array__+=("${BASH_REMATCH[1]}")
      elif [[ $line =~ ^\'(.*)\'\s*\\?$ ]]; then
        __tmp_array__+=("${BASH_REMATCH[1]}")
      elif [[ $line =~ ^([^[:space:]][^\\]*)\\?$ ]]; then
        __tmp_array__+=("${BASH_REMATCH[1]}")
      else
        echo "Warning: Skipping malformed array entry: '$line'" >&2
        continue
      fi
      continue
    fi

    # Start of multi-line array: name=( or name=( \
    if [[ $line =~ ^([a-zA-Z_][a-zA-Z0-9_]*)=\(\s*\\?$ ]]; then
      current_var="${BASH_REMATCH[1]}"
      if [[ $current_var == "$source_var" ]]; then
        storing_array=1
        __tmp_array__=()
      fi
      continue
    fi

    # One-line array: name=( "a" 'b' c )
    if [[ $line =~ ^([a-zA-Z_][a-zA-Z0-9_]*)=\(\s*(.*)\s*\)$ ]]; then
      local varname="${BASH_REMATCH[1]}"
      local inner="${BASH_REMATCH[2]}"
      if [[ $varname == "$source_var" ]]; then
        __tmp_array__=()
        # Parse tokens in one-line array
        while [[ $inner =~ ^[[:space:]]*(\"[^\"]*\"|\'[^\']*\'|[^[:space:]]+)[[:space:]]*(.*)$ ]]; do
          local token="${BASH_REMATCH[1]}"
          inner="${BASH_REMATCH[2]}"
          if [[ $token =~ ^\"(.*)\"$ || $token =~ ^\'(.*)\'$ ]]; then
            __tmp_array__+=("${BASH_REMATCH[1]}")
          else
            __tmp_array__+=("$token")
          fi
        done
        if [[ -n "$inner" && ! "$inner" =~ ^[[:space:]]*$ ]]; then
          echo "Warning: Skipping malformed tokens in one-line array: '$inner'" >&2
        fi
        if [[ ${#__tmp_array__[@]} -gt 0 ]]; then
          unset "$dest_var" 2>/dev/null || true
          declare -g -a "$dest_var"
          declare -n __dst="$dest_var"
          __dst=("${__tmp_array__[@]}")
          unset -n __dst
          __last_type="array"
          unset __tmp_array__
          return 0
        fi
      fi
      continue
    fi

    # Scalar: name=value
    if [[ $line =~ ^([a-zA-Z_][a-zA-Z0-9_]*)=(.*)$ ]]; then
      local varname="${BASH_REMATCH[1]}"
      local val="${BASH_REMATCH[2]}"
      if [[ $varname == "$source_var" ]]; then
        # Trim trailing comments if not quoted
        if [[ ! $val =~ ^[\"\'] ]]; then
          val="${val%%#*}"
          val="${val%"${val##*[![:space:]]}"}"
        fi
        # Strip matching quotes
        if [[ $val =~ ^\"(.*)\"$ || $val =~ ^\'(.*)\'$ ]]; then
          val="${BASH_REMATCH[1]}"
        fi
        printf -v "$dest_var" '%s' "$val"
        __last_type="string"
        return 0
      fi
      continue
    fi

    # Skip malformed lines
    echo "Warning: Skipping unrecognized line: '$line'" >&2
  done < "$conf_file"

  # Handle incomplete array at EOF
  if (( storing_array )) && [[ $current_var == "$source_var" && ${#__tmp_array__[@]} -gt 0 ]]; then
    echo "Warning: Incomplete array definition for '$source_var' at EOF" >&2
    unset "$dest_var" 2>/dev/null || true
    declare -g -a "$dest_var"
    declare -n __dst="$dest_var"
    __dst=("${__tmp_array__[@]}")
    unset -n __dst
    __last_type="array"
    unset __tmp_array__
    return 0
  fi

  echo "Variable '$source_var' not found in $conf_file" >&2
  return 2
} # End of function: read_var_from_file()

################################################################################################
# Write variables/arrays to file
################################################################################################
write_var_to_file() {
  # write_var_to_file <config-file> <varname>
  # - Reads the value of <varname> from the current shell (string or array)
  # - Writes/updates it in <config-file>
  # Replace an existing definition (scalar, one-line array, or multi-line array), or append if it doesn’t exist.
  # Creates a backup <file>.bak before modifying.
  local conf_file="$1"
  local name="$2"

  ## pre checks
  if [[ -z "$conf_file" || -z "$name" ]]; then
    echo "Usage: write_var_to_file <config-file> <varname>" >&2
    return 1
  fi
  if [[ ! -f "$conf_file" ]]; then
    echo "File not found: $conf_file" >&2
    return 1
  fi
  if ! declare -p "$name" &>/dev/null; then
    echo "Variable '$name' is not set in the current shell" >&2
    return 1
  fi

  ## Build replacement text (safe, quoted)
  local repl type
  if declare -p "$name" 2>/dev/null | grep -q 'declare -a'; then
    type="array"
    local -a _vals
    eval '_vals=( "${'"$name"'[@]}" )'   # Read array values
    repl="$name=( \\"
    local v
    for v in "${_vals[@]}"; do
      v="${v//\\/\\\\}"
      v="${v//\"/\\\"}"
      repl+=$'\n'"\"$v\" \\"
    done
    repl+=$'\n'")"
  else
    type="string"
    local _val esc
    eval "_val=\${$name}"     # Read scalar
    esc="${_val//\\/\\\\}"
    esc="${esc//\"/\\\"}"
    repl="$name=\"$esc\""
  fi

  ## Create a backup
  cp -p -- "$conf_file" "$conf_file.bak" || {
    echo "Warning: could not create backup ${conf_file}.bak" >&2
  }

  ## Replace or append using awk
  awk -v var="$name" -v repl="$repl" '
    BEGIN {
      in_block = 0; replaced = 0;
    }
    function starts_var(line) {
      return (line ~ ("^" var "="));
    }
    function starts_array_block(line) {
      return (line ~ ("^" var "=\\("));
    }
    {
      if (in_block == 0) {
        if (starts_var($0)) {
          if (starts_array_block($0)) {
            in_block = 1; next;
          } else {
            if (!replaced) { print repl; replaced = 1; }
            next;
          }
        } else {
          print;
        }
      } else {
        if ($0 ~ /^\)$/) {
          if (!replaced) { print repl; replaced = 1; }
          in_block = 0;
          next;
        } else {
          next;
        }
      }
    }
    END {
      if (!replaced) {
        print "";
        print repl;
      }
    }
  ' "$conf_file" > "${conf_file}.tmp" && mv "${conf_file}.tmp" "$conf_file"
} # End of function: write_var_to_file()
