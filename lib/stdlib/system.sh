# Some global variable declarations

## stdlib_current_state holds the state of the last run command
declare -g stdlib_current_state

## stdlib_change reports if changes were made in the current title
declare -g stdlib_state_change
declare -g stdlib_resource_change

## stdlib_resource_changes keeps track of how many changes were made
declare -g stdlib_resource_changes=0

## stdlib_remote_copy is a list of data and profiles that need copied to a remote node
declare -Ag stdlib_remote_copy


# Colors
declare stdlib_color_blue='\e[0;34m'
declare stdlib_color_green='\e[1;32m'
declare stdlib_color_red='\e[0;31m'
declare stdlib_color_yellow='\e[1;33m'
declare stdlib_color_reset='\e[0m'

# These functions print colored lines
function stdlib.debug {
  if stdlib.debug? ; then
    echo -e "${stdlib_color_blue} ===> (debug) ${stdlib_title} ${stdlib_subtitle}${stdlib_color_reset} ${@}" >&2
  fi
}

function stdlib.info {
  echo -e "${stdlib_color_green} ===> (info)  ${stdlib_title} ${stdlib_subtitle}${stdlib_color_reset} ${@}"
}

function stdlib.warn {
  echo -e "${stdlib_color_yellow} ===> (warn)  ${stdlib_title} ${stdlib_subtitle}${stdlib_color_reset} ${@}"
}

function stdlib.error {
  echo -e "${stdlib_color_red} ===> (error) ${stdlib_title} ${stdlib_subtitle}${stdlib_color_reset} ${@}" >&2
}


# These commands are simple helpers to detect how Waffles was run.
function stdlib.noop? {
  [[ -n $WAFFLES_NOOP ]]
}

function stdlib.debug? {
  [[ -n $WAFFLES_DEBUG ]]
}


# stdlib.title is a section/subsection currently being run
function stdlib.title {
  stdlib_title=""
  stdlib_subtitle=""
  stdlib_title="$@"
  stdlib_state_change="false"
  stdlib_resource_change="false"
}

function stdlib.subtitle {
  stdlib_subtitle=""
  stdlib_subtitle="$@"
  stdlib_resource_change="false"
}


# stdlib.mute turns off command output
# and prints the command being run.
function stdlib.mute {
  if stdlib.noop? ; then
    stdlib.info "(noop) $@"
  else
    stdlib.info "Running \"$@\""
    eval $@ &>/dev/null
    return $?
  fi
}

# stdlib.debug_mute turns off command output
# and prints the command being run at debug level
function stdlib.debug_mute {
  if stdlib.noop? ; then
    stdlib.debug "(noop) $@"
  else
    stdlib.debug "Running \"$@\""
    eval $@ &>/dev/null
    return $?
  fi
}


# stdlib.exec just runs the command
function stdlib.exec {
  if stdlib.noop? ; then
    stdlib.info "(noop) $@"
  else
    stdlib.info "Running \"$@\""
    eval $@
    return $?
  fi
}


# stdlib.capture_error will report back anything on fd 2.
# unfortunately a lot of noise usually ends up on fd 2,
# so this could be a little buggy.
function stdlib.capture_error {
  if stdlib.noop? ; then
    stdlib.info "(noop) $@"
  else
    local _err
    stdlib.info "Running \"$@\""
    _err=$(eval "$@" 2>&1 >/dev/null)
    if [[ $? != 0 ]]; then
      stdlib.error "Errors occurred:"
      stdlib.error "$_err"
      if [[ "$WAFFLES_EXIT_ON_ERROR" == true ]]; then
        stdlib.error "Halting run."
        exit 1
      else
        return $?
      fi
    else
      return 0
    fi
  fi
}


# stdlib.dir is a clean way of getting the current dir of the script being run.
function stdlib.dir {
  if [[ $# -gt 0 ]]; then
    echo $(readlink -f "${1%/*}")
  fi
}


# stdlib.include is a more intelligent "source".
# It will warn if the file does not exist, rather than erroring.
function stdlib.include {
  if [[ $# -gt 0 ]]; then
    if [[ -f $1 ]]; then
      source -- "$1"
    else
      stdlib.warn "File not found: $1"
    fi
  fi
}


# stdlib.profile is a shortcut to run scripts in "$WAFFLES_SITE_DIR/profiles"
# If running in REMOTE mode, a list of profiles to copy is built
function stdlib.profile {
  if [[ $# -gt 0 ]]; then
    local _script_path
    local _profile
    local _file
    local _host
    if [[ $1 =~ [/] ]]; then
      stdlib.split "$1" '/'
      _profile="${__split[0]}"
      _file="${__split[1]}"
    else
      _profile="$1"
      _file="init.sh"
    fi

    if [[ $_profile == "host_files" ]]; then
      if [[ -n $server ]]; then
        _host="${server%%.*}"
      else
        _host=$(hostname)
        _host=${_host%%.*}
      fi
      _profile="host_files/$_host"
    fi

    if [[ -f "$WAFFLES_SITE_DIR/profiles/$_profile/scripts/${_file}.sh" ]]; then
      _script_path="$WAFFLES_SITE_DIR/profiles/$_profile/scripts/${_file}.sh"
    elif [[ -f "$WAFFLES_SITE_DIR/profiles/$_profile/scripts/init.sh" ]]; then
      _script_path="$WAFFLES_SITE_DIR/profiles/$_profile/scripts/init.sh"
    elif [[ ! -d "$WAFFLES_SITE_DIR/profiles/$_profile" ]]; then
      _profile=""
    fi

    if [[ -n $_profile ]]; then
      if [[ -n $WAFFLES_REMOTE ]]; then
        stdlib_remote_copy[profiles/$_profile]=1
      elif [[ -n $_script_path ]]; then
        stdlib.debug "Applying Profile: $_profile"
        # Check for profile data
        if [[ -f "$WAFFLES_SITE_DIR/profiles/$_profile/data.sh" ]]; then
          stdlib.debug "Found Profile data for $_profile"
          stdlib.include "$WAFFLES_SITE_DIR/profiles/$_profile/data.sh"
        fi
        stdlib.debug "Running Profile script: $_script_path"
        stdlib.include "$_script_path"
      fi
    else
      stdlib.debug "Profile not found: $1"
    fi
  fi
}

# stdlib.git_profile will check a profile out from a git repository.
# It will be ignored if running in REMOTE mode,
# so repositories are only created when Waffles is run locally.
#
# stdlib.git_profile repositories must be named:
#
#   waffles-profile-$profile_name
#
# stdlib.git_profiles must follow the following syntax:
#
#   stdlib.git_profile https://github.com/jtopjian/waffles-profile-openstack
#   stdlib.git_profile https://github.com/jtopjian/waffles-profile-openstack branch dev
#   stdlib.git_profile https://github.com/jtopjian/waffles-profile-openstack tag 0.5.1
#   stdlib.git_profile https://github.com/jtopjian/waffles-profile-openstack commit 023a83
function stdlib.git_profile {
  # Only act if Waffles is being run locally
  if [[ -z $WAFFLES_REMOTE ]]; then
    if [[ $# -gt 0 ]]; then
      stdlib.split "$1" "/"
      stdlib.array_pop __split _repo_name
      stdlib.split "$_repo_name" "-"
      stdlib.array_pop __split _profile
      stdlib.debug "git profile repo: $_repo_name"
      stdlib.debug "git profile profile name: $_profile"
      if [[ $# -eq 1 ]]; then
        stdlib.git --state latest --name "$WAFFLES_SITE_DIR/profiles/$_profile" --source "$1"
      elif [[ $# -eq 3 ]]; then
        case "$2" in
          branch)
            stdlib.git --state latest --name "$WAFFLES_SITE_DIR/profiles/$_profile" --branch "$3" --source "$1"
            ;;
          tag)
            stdlib.git --name "$WAFFLES_SITE_DIR/profiles/$_profile" --tag "$3" --source "$1"
            ;;
          commit)
            stdlib.git --name "$WAFFLES_SITE_DIR/profiles/$_profile" --commit "$3" --source "$1"
            ;;
          *)
            stdlib.git --state latest --name "$WAFFLES_SITE_DIR/profiles/$_profile" --source "$1"
            ;;
        esac
      fi
    fi
  fi
}

# stdlib.git_profile_push works just like stdlib.git_profile,
# but the git repository is downloaded on the Waffles "server" and pushed to the node.
# This is useful in cases when the nodes do not have direct access to the git repository.
function stdlib.git_profile_push {
  # Only act if Waffles is being run in REMOTE mode
  if [[ -n $WAFFLES_REMOTE ]]; then
    if [[ $# -gt 0 ]]; then
      stdlib.split "$1" "/"
      stdlib.array_pop __split _repo_name
      stdlib.split "$_repo_name" "-"
      stdlib.array_pop __split _profile
      stdlib.debug "git profile repo: $_repo_name"
      stdlib.debug "git profile profile name: $_profile"

      # Create and manage a local cache directory for the git repository
      _whoami=$(id -un)
      _cache_dir="$WAFFLES_SITE_DIR/.gitcache/roles/$role/profiles"
      stdlib.directory --name "$_cache_dir" --owner $_whoami --group $_whoami --parent true
      if [[ $# -eq 1 ]]; then
        stdlib.git --state latest --name "$_cache_dir/$_profile" --source "$1"
      elif [[ $# -eq 3 ]]; then
        case "$2" in
          branch)
            stdlib.git --state latest --name "$_cache_dir/$_profile" --branch "$3" --source "$1"
            ;;
          tag)
            stdlib.git --name "$_cache_dir/$_profile" --tag "$3" --source "$1"
            ;;
          commit)
            stdlib.git --name "$_cache_dir/$_profile" --commit "$3" --source "$1"
            ;;
          *)
            stdlib.git --state latest --name "$_cache_dir/$_profile" --source "$1"
            ;;
        esac
        stdlib_remote_copy[$_cache_dir/$_profile]=1
      fi
    fi
  fi
}

# stdlib.data is a shortcut to source data in "$WAFFLES_SITE_DIR/data"
function stdlib.data {
  if [[ $# -gt 0 ]]; then
    local _script_path
    local _data
    local _file
    if [[ $1 =~ [/] ]]; then
      stdlib.split "$1" '/'
      _data="${__split[0]}"
      _file="${__split[1]}"
      _script_path="$WAFFLES_SITE_DIR/data/$data/${_file}.sh"
    else
      if [[ -f "$WAFFLES_SITE_DIR/data/${1}.sh" ]]; then
        _data="data/${1}.sh"
        _script_path="$WAFFLES_SITE_DIR/data/${1}.sh"
      elif [[ -f "$WAFFLES_SITE_DIR/data/${1}/init.sh" ]]; then
        _data="data/${1}"
        _script_path="$WAFFLES_SITE_DIR/data/${1}/init.sh"
      fi
    fi

    if [[ -n $_data && -n $_script_path ]]; then
      if [[ -n $WAFFLES_REMOTE ]]; then
        stdlib_remote_copy[$_data]=1
      else
        stdlib.include "$_script_path"
      fi
    else
      stdlib.warn "Data not found: $1"
    fi
  fi
}


# stdlib.command_exists is a simple alias for `which`
function stdlib.command_exists {
  which $1 &>/dev/null
}


# String functions

# stdlib.split splits a string
# $1 = string
# $2 = delimiter
declare -ax __split
function stdlib.split {
  if [[ -z $2 ]]; then
    echo "$1"
  fi

  __split=()
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
}


# stdlib.trim trims whitespace from a string
# $1 = string
function stdlib.trim {
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


# Array functions

# stdlib.array_length returns the length of an array
# $1 = array
function stdlib.array_length {
  local -n _arr="$1"
  echo "${#_arr[@]:-0}"
}

# stdlib.array_push adds elements to the end of an array
# $1 = array
# $2+ = elements to push
function stdlib.array_push {
  local -n _arr=$1
  shift

  while [[ $# -gt 0 ]]; do
    _arr+=("$1")
    shift
  done
}

# stdlib.array_pop pops the last element from an array
# $1 = array
# $2 = optional variable to pop to
function stdlib.array_pop {
  local -n _arr="$1"
  local _arr_length=$(stdlib.array_length $1)
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

# stdlib.array_shift pops the first element from an array
# $1 = array
# $2 = optional variable to pop to
function stdlib.array_shift {
  local -n _arr="$1"
  local _arr_length=$(stdlib.array_length $1)

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

# stdlib.array_unshift adds elements to the beginning of an array
# $1 = array
# $2+ = elements
function stdlib.array_unshift {
  local -n _arr="$1"
  shift

  if [[ -n $_arr ]]; then
    while [[ $# -gt 0 ]]; do
      _arr=("$1" "${_arr[@]}")
      shift
    done
  fi
}

# stdlib.array_join joins an array into a string
# $1 = array
# $2 = delimiter
function stdlib.array_join {
  if [[ $# -eq 2 ]]; then
    local -n _arr="$1"
    local _delim="$2"
    local _arr_length=$(stdlib.array_length $1)
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

# stdlib.array_contains checks if an element exists in an array
# $1 = array
# $2 = needle
function stdlib.array_contains {
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

# stdlib.hash_keys returns the keys of a hash / assoc array
# $1 = hash/associative array
# $2 = array to store keys
function stdlib.hash_keys {
  if [[ $# -eq 2 ]]; then
    local -n _hash="$1"
    local -n _keys="$2"

    _keys=(${!_hash[@]})
  fi
}
