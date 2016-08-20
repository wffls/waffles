# String functions

# string.split splits a string
# $1 = string
# $2 = delimiter
declare -ax __split
string.split() {
  if [[ $# -eq 2 ]]; then
    __split=()
    if [[ -n $1 ]]; then
      log.debug "Running split: string $1, delimiter $2"
      local _string="$1"
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
