# Array functions

# array.length returns the length of an array
# $1 = array
function array.length {
  local -n _arr="$1"
  echo "${#_arr[@]:-0}"
}

# array.push adds elements to the end of an array
# $1 = array
# $2+ = elements to push
function array.push {
  local -n _arr=$1
  shift

  while [[ $# -gt 0 ]]; do
    _arr+=("$1")
    shift
  done
}

# array.pop pops the last element from an array
# $1 = array
# $2 = optional variable to pop to
function array.pop {
  local -n _arr="$1"
  local _arr_length=$(array.length $1)
  local _arr_element

  if [[ -n $2 ]]; then
    local -n _pop="$2"
  else
    local _pop
  fi

  if [[ -n $_arr ]] && (( $_arr_length >= 1 )); then
    _arr_element=$(( $_arr_length - 1 ))
    _pop="${_arr[$_arr_element]}"
    unset "_arr[$_arr_element]"
  fi
}

# array.shift pops the first element from an array
# $1 = array
# $2 = optional variable to pop to
function array.shift {
  local -n _arr="$1"
  local _arr_length=$(array.length $1)

  if [[ -n $2 ]]; then
    local -n _pop="$2"
  else
    local _pop
  fi

  if [[ -n ${_arr} ]] && (( $_arr_length >= 1 )); then
    _pop="${_arr[0]}"
    unset '_arr[0]'
    _arr=("${_arr[@]}")

  fi
}

# array.unshift adds elements to the beginning of an array
# $1 = array
# $2+ = elements
function array.unshift {
  local -n _arr="$1"
  shift

  if [[ -n $_arr ]]; then
    while [[ $# -gt 0 ]]; do
      _arr=("$1" "${_arr[@]}")
      shift
    done
  fi
}

# array.join joins an array into a string
# $1 = array
# $2 = delimiter
function array.join {
  if [[ $# -eq 2 ]]; then
    local -n _arr="$1"
    local _delim="$2"
    local _arr_length=$(array.length $1)
    local _string
    local _pop

    while [[ $_arr_length -gt 0 ]]; do
      _pop="${_arr[0]}"
      unset '_arr[0]'
      _arr=("${_arr[@]}")
      _string="${_string:+$_string$_delim}${_pop}"
      _arr_length=$(( $_arr_length - 1 ))
    done

    echo "$_string"
  fi
}

# array.contains checks if an element exists in an array
# $1 = array
# $2 = needle
function array.contains {
  if [[ $# -eq 2 ]]; then
    local -n _arr="$1"
    local _needle="$2"
    local _exists=1

    for _element in "${_arr[@]}"; do
      if [[ $_element == $_needle ]]; then
        _exists=0
        break
      fi
    done

    return $_exists
  fi
}

# hash.keys returns the keys of a hash / assoc array
# $1 = hash/associative array
# $2 = array to store keys
function hash.keys {
  if [[ $# -eq 2 ]]; then
    local -n _hash="$1"
    local -n _keys="$2"

    _keys=(${!_hash[@]})
  fi
}
