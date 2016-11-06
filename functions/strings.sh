# String functions

# string.split splits a string
# $1 = string
# $2 = delimiter
declare -ax __split
string.split() {
  if [[ $# -eq 1 ]]; then
    # If only one argument, split by a single space.
    __split=()
    log.debug "Running split: string $1, delimiter ' '"
    __split=($1)
  fi

  if [[ $# -eq 2 ]]; then
    __split=()
    if [[ -n $1 ]]; then
      log.debug "Running split: string $1, delimiter '$2'"
      local _string="$1"

      if [[ "$2" == " " ]]; then
        # A blank space was passed in
        __split=($1)
      else
        local _delim="$2"
        while true ; do
          if [[ ! $_string == *"$_delim"* ]]; then
            __split+=("$_string")
            break
          else
            __split+=("${_string%%$_delim*}")
            _string="${_string#*$_delim}"
          fi
        done
      fi
    fi
  fi
}

# string.trim trims whitespace from a string
# $1 = string
string.trim() {
  if [[ $# -gt 0 ]]; then
    shopt -s extglob
    local _trim="$1"
    _trim="${_trim##*( )}"
    _trim="${_trim%%*( )}"
    shopt -u extglob
    echo "$_trim"
  else
    echo ""
  fi
}
