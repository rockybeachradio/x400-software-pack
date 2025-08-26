#!/bin/bash
set -euo pipefail

################################################################################################
# File: read_write_config_files.sh
# Author: Andreas
# Date: 20250826
# Purpose:
# - read_var_from_file() - Read variable from file
# - write_var_to_file() - Write varibale to file
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

################################################################################################
# Calls Examples Read variables from file & write variable to file
################################################################################################
call_examples_read_variables_from_files(){
  # Call: Read variables/arrays from file
  
  ## put this to the callsing bash script to include this file --> needed to access the functions
  #source read_write_config_files.sh      # Include shell script file where the functions are included

  # Variable declaration
  local source_file="env.conf"                  # Name and path to the configuration file

  local backupPaths                 # name of the variable in the source file
  local backupPaths_from_file       # name of the variable in the script. If not given, source_var_name_in_file is uesd.

  # Array -> read backupPaths from file and store it in backupPaths_from_file
  read_var_from_file "$source_file" backupPaths backupPaths_from_file
    echo "type: $__last_type"        # array
    declare -p backupPaths_from_file

    if is_array backupPaths_from_file; then    # iterate using nameref
      declare -n arr_ref=backupPaths_from_file
      for p in "${arr_ref[@]}"; do
        echo "→ $p"
      done 
    fi

  # Scalar -> read github_repository from file and store it in github_repository_from_file
  read_var_from_file "$source_file" github_repository github_repository_from_file
    echo "type: $__last_type"        # string
    echo "$github_repository_from_file"

  # Default: The variable_name used in the file is the variable_name used to store the value(s) in.
  read_var_from_file "$source_file" github_repository
    echo "type: $__last_type"        # string
    echo "$github_repository"

} ##Ende function: call_examples_read_variables_from_files()


########################################
# Helper: is the given NAME an array?
########################################
is_array() {
  local name="$1"
  local decl
  decl="$(declare -p "$name" 2>/dev/null || true)"
  [[ "$decl" == "declare -a"* ]]
}

######################################################
check_if_var_is_array(){
  local source_var_name_in_file=backupPaths
# Check if variable is string/scalar or array
  declare -p "$source_var_name_in_file" 2>/dev/null | grep -q 'declare \-a'
  if [[ $? -eq 0 ]]; then
      echo "$source_var_name_in_file is an array"
  else
      echo "$source_var_name_in_file is a string"
  fi
} # Ende function: check_if_var_is_array()


######################################################
call_examples_write_variable_to_files(){
  # Call: Write variables/arrays to file

  ## put this to the callsing bash script to include this file --> needed to access the functions
  #source read_write_config_files.sh      # Include shell script file where the functions are included

  # Variables declaration
  local destination_file=env.conf   # Name and path to the configuration file

  github_token=ghp_xxxxxx
  branch_name="main"
  commit_email="andreas@klipper-74e8755"
  backupPaths=( "printer_data/config/*" "mainsail-config/client.cfg" )
  backupPaths_2=( \
  "printer_data/config/*" \
  "printer_data/database/" \
  )

  # Write varibales back to destination_file
  write_var_to_file $destination_file github_token
  write_var_to_file $destination_file branch_name
  write_var_to_file $destination_file commit_email
  write_var_to_file $destination_file backupPaths   # writes as multiline block
  write_var_to_file $destination_file backupPaths_2
} # Ende function: call_examples_write_variable_to_files()


################################################################################################
# Read variables/arrays from file
################################################################################################
read_var_from_file() {
  # read_var_from_file <config-file> <source-var-in-file> [dest-var-in-shell]
  # After calling, the value from <source-var-in-file> in the <config-file> is stored into <dest-var-in-shell> (or the same name if omitted).
  # Gives back a variable or an array.
  # Sets __last_type to "array" or "string".
    local conf_file="$1"
    local source_var="$2"
    local dest_var="${3:-$2}"

    if [[ -z "$conf_file" || -z "$source_var" ]]; then
        echo "Usage: read_var_from_file <config-file> <source-var> [dest-var]"
        return 1
    fi
    if [[ ! -f "$conf_file" ]]; then
        echo "File not found: $conf_file"
        return 1
    fi
    # Validate destination variable name
    if [[ ! "$dest_var" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo "Invalid destination variable name: $dest_var"
        return 1
    fi

    local current_var=""
    local storing_array=0
    __last_type=""

    # temp array buffer
    local -a __tmp_array__=()
    local entry

    while IFS= read -r raw; do
        # trim
        local line="${raw#"${raw%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        # skip empty & comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        # collecting multi-line array?
        if (( storing_array )); then
            # end of array
            if [[ $line =~ ^\)$ ]]; then
                storing_array=0
                current_var=""
                # if we were collecting the target, finalize now
                if [[ ${#__tmp_array__[@]} -gt 0 ]]; then
                    unset "$dest_var" 2>/dev/null  || true
                    declare -g -a "$dest_var=()"
                    eval "$dest_var+=(\"\${__tmp_array__[@]}\")"
                    __last_type="array"
                    unset __tmp_array__
                    return 0
                fi
                continue
            fi

            # Array entry (quoted or unquoted), allow trailing backslash
            if [[ $line =~ ^\"(.*)\"\s*\\?$ ]]; then
                __tmp_array__+=("${BASH_REMATCH[1]}")
                continue
            elif [[ $line =~ ^\'(.*)\'\s*\\?$ ]]; then
                __tmp_array__+=("${BASH_REMATCH[1]}")
                continue
            elif [[ -n "$line" ]]; then
                entry="${line%\\}"
                __tmp_array__+=("$entry")
                continue
            else
                # ignore anything unexpected
                continue
            fi
        fi

        # start of multi-line array: name=( \   or   name=(
        if [[ $line =~ ^([a-zA-Z_][a-zA-Z0-9_]*)=\(\s*\\?$ ]]; then
            current_var="${BASH_REMATCH[1]}"
            if [[ $current_var == "$source_var" ]]; then
                storing_array=1
                __tmp_array__=()
            fi
            continue
        fi

        # one-line array: name=( "a" 'b' c )
        if [[ $line =~ ^([a-zA-Z_][a-zA-Z0-9_]*)=\(\s*(.*)\s*\)$ ]]; then
            local varname="${BASH_REMATCH[1]}"
            local inner="${BASH_REMATCH[2]}"
            if [[ $varname == "$source_var" ]]; then
                __tmp_array__=()
                # parse quoted tokens
                while [[ $inner =~ ^[[:space:]]*\"([^\"]*)\"[[:space:]]*(.*)$ ]]; do
                    __tmp_array__+=("${BASH_REMATCH[1]}")
                    inner="${BASH_REMATCH[2]}"
                done
                while [[ $inner =~ ^[[:space:]]*\'([^\']*)\'[[:space:]]*(.*)$ ]]; do
                    __tmp_array__+=("${BASH_REMATCH[1]}")
                    inner="${BASH_REMATCH[2]}"
                done
                # parse remaining unquoted tokens (split on spaces)
                # shellcheck disable=SC2206
                local rest_tokens=()
                read -r -a rest_tokens <<<"$inner" || true
                if ((${#rest_tokens[@]})); then
                    __tmp_array__+=("${rest_tokens[@]}")
                fi

                unset "$dest_var" 2>/dev/null
                declare -g -a "$dest_var=()"
                eval "$dest_var+=(\"\${__tmp_array__[@]}\")"
                __last_type="array"
                unset __tmp_array__
                return 0
            fi
            continue
        fi

        # scalar: name=value  (value may be quoted or unquoted)
        if [[ $line =~ ^([a-zA-Z_][a-zA-Z0-9_]*)=(.*)$ ]]; then
            local varname="${BASH_REMATCH[1]}"
            local val="${BASH_REMATCH[2]}"

            if [[ $varname != "$source_var" ]]; then
                continue
            fi

            # trim trailing comments if not quoted
            if [[ ! $val =~ ^[\"\'] ]]; then
                val="${val%%#*}"
                val="${val%"${val##*[![:space:]]}"}"
            fi

            # strip matching quotes
            if [[ $val =~ ^\"(.*)\"$ ]]; then
                val="${BASH_REMATCH[1]}"
            elif [[ $val =~ ^\'(.*)\'$ ]]; then
                val="${BASH_REMATCH[1]}"
            fi

            # assign to destination (global in caller)
            printf -v "$dest_var" '%s' "$val"
            __last_type="string"
            return 0
        fi

        # otherwise ignore
    done < "$conf_file"

    # If EOF while collecting target array (missing ')' but entries gathered)
    if (( storing_array )) && [[ ${#__tmp_array__[@]} -gt 0 ]]; then
        unset "$dest_var" 2>/dev/null
        declare -g -a "$dest_var=()"
        eval "$dest_var+=(\"\${__tmp_array__[@]}\")"
        __last_type="array"
        unset __tmp_array__
        return 0
    fi

    echo "Variable '$source_var' not found in $conf_file"
    return 2
}


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
        echo "Usage: write_var_to_file <config-file> <varname>"
        return 1
    fi
    if [[ ! -f "$conf_file" ]]; then
        echo "File not found: $conf_file"
        return 1
    fi
    if ! declare -p "$name" &>/dev/null; then
        echo "Variable '$name' is not set in the current shell"
        return 1
    fi

    ## Build replacement text (safe, quoted)
    local repl type
    if declare -p "$name" 2>/dev/null | grep -q 'declare \-a'; then
        type="array"
        local -a _vals
        eval '_vals=(\"\${$name[@]}\")'   # Read array values

        repl="$name=( \\"
        local v
        for v in "${_vals[@]}"; do
            # Escape backslashes and double quotes
            v="${v//\\/\\\\}"
            v="${v//\"/\\\"}"
            repl+=$'\n'"\"$v\" \\"
        done
        repl+=$'\n'")"
    else
        type="string"
        local _val esc
        eval "_val=\${$name}"     # Read scalar
        # Escape backslashes and double quotes
        esc="${_val//\\/\\\\}"
        esc="${esc//\"/\\\"}"
        repl="$name=\"$esc\""
    fi

    ## Create a backup
    cp -p -- "$conf_file" "$conf_file.bak" || {
        echo "Warning: could not create backup ${conf_file}.bak"
    }

    ## Replace or append using awk (handles scalar, one-line array, multi-line array)
    awk -v var="$name" -v repl="$repl" '
        BEGIN {
            in_block = 0; replaced = 0;
        }
        # Helper to detect the start of the target variable definition
        function starts_var(line) {
            # start of any assignment for var: var=
            return (line ~ ("^" var "="));
        }
        # Helper to detect start of an array block: var=(
        function starts_array_block(line) {
            return (line ~ ("^" var "=\\("));
        }

        {
            if (in_block == 0) {
                if (starts_var($0)) {
                    # If this is an array block, consume until the closing ')'
                    if (starts_array_block($0)) {
                        in_block = 1; next;  # skip this line
                    } else {
                        # Single-line assignment OR one-line array -> replace this line
                        if (!replaced) { print repl; replaced = 1; }
                        next; # skip original line
                    }
                } else {
                    print;  # pass through unrelated lines
                }
            } else {
                # We are in a multi-line array block; look for closing ')'
                if ($0 ~ /^\)$/) {
                    # End of block: emit replacement once
                    if (!replaced) { print repl; replaced = 1; }
                    in_block = 0;
                    next;  # skip the closing line
                } else {
                    next;  # skip lines inside the old block
                }
            }
        }
        END {
            # If not found/replaced, append to end
            if (!replaced) {
                print "";
                print repl;
            }
        }
    ' "$conf_file" > "${conf_file}.tmp" && mv "${conf_file}.tmp" "$conf_file"
} # End function: write_var_to_file()
