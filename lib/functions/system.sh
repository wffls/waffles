# Some global variable declarations

## _waffles_remote_copy is a list of data and profiles that need copied to a remote node
## _waffles_remote_gitcache_copy is a list of git repositories that need copied to a remote node
declare -Ag _waffles_remote_copy
declare -Ag _waffles_remote_gitcache_copy

# Colors
declare log_color_blue='\e[0;34m'
declare log_color_green='\e[1;32m'
declare log_color_red='\e[0;31m'
declare log_color_yellow='\e[1;33m'
declare log_color_reset='\e[0m'

# These functions print colored lines
function waffles.color {
  [[ -n $WAFFLES_COLOR_OUTPUT ]]
}

function log.debug {
  if waffles.debug ; then
    if waffles.color ; then
      echo -e "${log_color_blue}$(date +%H:%M:%S) (debug) ${waffles_title}${waffles_subtitle}${log_color_reset}${@}" >&2
    else
      echo -e "$(date +%H:%M:%S) (debug) ${waffles_title}${waffles_subtitle}${@}" >&2
    fi
  fi
}

function log.info {
  if waffles.color ; then
    echo -e "${log_color_green}$(date +%H:%M:%S) (info)  ${waffles_title}${waffles_subtitle}${log_color_reset}${@}" >&2
  else
    echo -e "$(date +%H:%M:%S) (info)  ${waffles_title}${waffles_subtitle}${@}" >&2
  fi
}

function log.warn {
  if waffles.color ; then
    echo -e "${log_color_yellow}$(date +%H:%M:%S) (warn)  ${waffles_title}${waffles_subtitle}${log_color_reset}${@}" >&2
  else
    echo -e "$(date +%H:%M:%S) (warn)  ${waffles_title}${waffles_subtitle}${@}" >&2
  fi
}

function log.error {
  if waffles.color ; then
    echo -e "${log_color_red}$(date +%H:%M:%S) (error) ${waffles_title}${waffles_subtitle}${log_color_reset}${@}" >&2
  else
    echo -e "$(date +%H:%M:%S) (error) ${waffles_title}${waffles_subtitle}${@}" >&2
  fi
}

# These commands are simple helpers to detect how Waffles was run.
function waffles.noop {
  [[ -n $WAFFLES_NOOP ]]
}

function waffles.debug {
  [[ -n $WAFFLES_DEBUG ]]
}


# waffles.title is a section/subsection currently being run
function waffles.title {
  waffles_title=""
  waffles_subtitle=""
  if [[ -n $@ ]]; then
    waffles_title="$@ "
  fi
  waffles_state_changed="false"
  waffles_resource_changed="false"
}

function waffles.subtitle {
  waffles_subtitle=""
  if [[ -n $@ ]]; then
    waffles_subtitle="$@ "
  fi
  waffles_resource_changed="false"
}


# exec.mute turns off command output
# and prints the command being run.
function exec.mute {
  if waffles.noop ; then
    log.info "(noop) $@"
  else
    log.info "Running \"$@\""
    eval $@ &>/dev/null
    return $?
  fi
}

# exec.debug_mute turns off command output
# and prints the command being run at debug level
function exec.debug_mute {
  if waffles.noop ; then
    log.debug "(noop) $@"
  else
    log.debug "Running \"$@\""
    eval $@ &>/dev/null
    return $?
  fi
}


# exec.run just runs the command
function exec.run {
  if waffles.noop ; then
    log.info "(noop) $@"
  else
    log.info "Running \"$@\""
    eval $@
    return $?
  fi
}


# exec.capture_error will report back anything on fd 2.
# unfortunately a lot of noise usually ends up on fd 2,
# so this could be a little buggy.
function exec.capture_error {
  if waffles.noop ; then
    log.info "(noop) $@"
  else
    local _err
    log.info "Running \"$@\""
    _err=$(eval "$@" 2>&1 >/dev/null)
    if [[ $? != 0 ]]; then
      log.error "Errors occurred:"
      log.error "$_err"
      if [[ "$WAFFLES_EXIT_ON_ERROR" == true ]]; then
        log.error "Halting run."
        exit 1
      else
        return $?
      fi
    else
      return 0
    fi
  fi
}


# waffles.dir is a clean way of getting the current dir of the script being run.
function waffles.dir {
  if [[ $# -gt 0 ]]; then
    echo $(readlink -f "${1%/*}")
  fi
}


# waffles.include is a more intelligent "source".
# It will warn if the file does not exist, rather than erroring.
function waffles.include {
  if [[ $# -gt 0 ]]; then
    if [[ -f $1 ]]; then
      source -- "$1"
    else
      log.warn "File not found: $1"
    fi
  fi
}


# waffles.stack imports a bundle of waffles profiles into the role.
function waffles.stack {
  if [[ $# -gt 0 ]]; then
    local _stack_path
    local _file
    local _host
    local profile_name
    local profile_path
    if [[ $1 =~ [/] ]]; then
      string.split "$1" '/'
      profile_name="${__split[0]}"
      _file="${__split[1]}"
    else
      log.debug "Invalid stack $1"
      return
    fi

    profile_path="$WAFFLES_SITE_DIR/profiles/$profile_name"

    if [[ -f "$profile_path/stacks/${_file}.sh" ]]; then
      _script_path="$profile_path/stacks/${_file}.sh"
    else
      log.debug "Invalid stack $1"
      return
    fi

    waffles.include "$_script_path"
  fi
}


# waffles.profile is a shortcut to run scripts in "$WAFFLES_SITE_DIR/profiles"
# If running in REMOTE mode, a list of profiles to copy is built
function waffles.profile {
  if [[ $# -gt 0 ]]; then
    local _script_path
    local _file
    local _host
    local profile_name
    local profile_path
    local profile_files
    if [[ $1 =~ [/] ]]; then
      string.split "$1" '/'
      profile_name="${__split[0]}"
      _file="${__split[1]}"
    else
      profile_name="$1"
      _file="init.sh"
    fi

    if [[ $profile_name == "host_files" ]]; then
      if [[ -n $WAFFLES_REMOTE ]]; then
        _host="$server"
      else
        _host=$(hostname)
      fi

      # Make sure _host was found, or return early
      if [[ -z $_host ]]; then
        return
      fi
      profile_name="host_files/$_host"
    fi

    profile_path="$WAFFLES_SITE_DIR/profiles/$profile_name"
    profile_files="$WAFFLES_SITE_DIR/profiles/$profile_name/files"

    if [[ -f "$profile_path/scripts/${_file}.sh" ]]; then
      _script_path="$profile_path/scripts/${_file}.sh"
    elif [[ -f "$profile_path/scripts/init.sh" ]]; then
      _script_path="$profile_path/scripts/init.sh"
    elif [[ ! -d "$profile_path" ]]; then
      profile_name=""
    fi

    if [[ -n $profile_name ]]; then
      if [[ -n $WAFFLES_REMOTE ]]; then
        _waffles_remote_copy[profiles/$profile_name]=1
      elif [[ -n $_script_path ]]; then
        log.debug "Running Profile script: $_script_path"
        waffles.title "$profile_name/$_file"
        waffles.include "$_script_path"
        waffles.title
        waffles.subtitle
      fi
    else
      log.debug "Profile not found: $1"
    fi
  fi
}

# git.profile will check a profile out from a git repository.
#
# git.profile repositories must be named:
#
#   waffles-profile-$profile_name
#
# git.profiles must follow the following syntax:
#
#   git.profile https://github.com/jtopjian/waffles-profile-openstack
#   git.profile https://github.com/jtopjian/waffles-profile-openstack --branch dev
#   git.profile https://github.com/jtopjian/waffles-profile-openstack --tag 0.5.1
#   git.profile https://github.com/jtopjian/waffles-profile-openstack --commit 023a83
#
# If you are deploying to remote nodes and those nodes do not have access to the git server:
#
#   git.profile https://github.com/jtopjian/waffles-profile-openstack --branch dev --push true
#
function git.profile {
  if [[ $# -gt 0 ]]; then
    local -A options
    local -a _arg_copy=("$@")
    local _git_repo _git_repo_name _profile
    local _git_repo_details

    array.shift _arg_copy _git_repo
    string.split "$_git_repo" "/"
    array.pop __split _git_repo_name
    string.split "$_git_repo_name" "-"
    array.pop __split _profile

    waffles.options.create_option branch "master"
    waffles.options.create_option commit
    waffles.options.create_option tag
    waffles.options.create_option push
    waffles.options.parse_options "${_arg_copy[@]}"

    log.debug "git profile repo: $_repo_name"
    log.debug "git profile profile name: $_profile"

    local _whoami=$(id -un)

    if [[ -n ${options[commit]} ]]; then
      _git_repo_details="--commit ${options[commit]} --source $_git_repo --owner $_whoami --group $_whoami"
    elif [[ -n ${options[tag]} ]]; then
      _git_repo_details="--tag ${options[tag]} --source $_git_repo --owner $_whoami --group $_whoami"
    else
      _git_repo_details="--branch ${options[branch]} --source $_git_repo --owner $_whoami --group $_whoami"
    fi

    if [[ -n $WAFFLES_REMOTE ]]; then
      if [[ -n ${options[push]} ]]; then
        # Create and manage a local cache directory for the git repository
        local _local_cache_dir="$WAFFLES_SITE_DIR/.gitcache/roles/$role/profiles/$_profile"
        os.directory --name "$_local_cache_dir" --owner $_whoami --group $_whoami --parent true
        git.repo --name "$_local_cache_dir" $_git_repo_details

        # Mark the cache to be copied to the remote node
        _waffles_remote_gitcache_copy[$_profile]=1
      fi
    else
      # If this is not REMOTE mode and push is set,
      # assume Waffles is being executed on a remote node and the profile has been copied
      if [[ -z ${options[push]} ]]; then
        git.repo --name "$WAFFLES_SITE_DIR/profiles/$_profile" $_git_repo_details
      fi
    fi
  fi
}

# waffles.data is a shortcut to source data in "$WAFFLES_SITE_DIR/data"
function waffles.data {
  if [[ $# -gt 0 ]]; then
    local _script_path
    local _data
    local _file
    local _pdata
    if [[ $1 =~ [/] ]]; then
      string.split "$1" '/'
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
      _pdata=1
      if [[ -n $WAFFLES_REMOTE ]]; then
        _waffles_remote_copy[$_data]=1
      else
        waffles.include "$_script_path"
      fi
    fi

    # Check and see if the data file matches a profile with included data
    # If so, and if Waffles is not being run in REMOTE mode, source it after
    # data under $WAFFLES_SITE_DIR/data has been sourced.
    if [[ -f "$WAFFLES_SITE_DIR/profiles/${1}/data.sh" ]]; then
      log.debug "Found Profile data for $1"
      _pdata=1
      if [[ -n $WAFFLES_REMOTE ]]; then
        _waffles_remote_copy[profiles/$1]=1
      else
        waffles.include "$WAFFLES_SITE_DIR/profiles/$1/data.sh"
      fi
    fi

    if [[ -z $_pdata ]]; then
      log.warn "Data not found: $1"
    fi
  fi
}


# waffles.command_exists is a simple alias for `which`
function waffles.command_exists {
  which $1 &>/dev/null
}


# exec.sudo runs a command as another user via sudo
# $1 = user
# $@ = command
function exec.sudo {
  if [[ $# -gt 1 ]]; then
    local _user
    array.shift "$@" _user
    exec.capture_error sudo -u "$_user" "$@"
  fi
}

# String functions

# string.split splits a string
# $1 = string
# $2 = delimiter
declare -ax __split
function string.split {
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


# string.trim trims whitespace from a string
# $1 = string
function string.trim {
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

# Convenience functions

# waffles.build_ini_file will build an ini file from a given hash
# $1 = config hash
# $2 = destination file
#
# Example hash:
#
#   declare -Ag data_openstack_keystone_settings
#   data_openstack_keystone_settings=(
#     [DEFAULT/verbose]="true"
#     [DEFAULT/debug]="true"
#   )
function waffles.build_ini_file {
  if [[ $# -eq 2 ]]; then
    local -n _config="$1"
    local _file="$2"

    for setting in "${!_config[@]}"; do
      string.split "$setting" "/"
      section="${__split[0]}"
      option="${__split[1]}"
      value="${_config[$setting]}"
      file.ini --file "$_file" --section "$section" --option "$option" --value "$value"
    done
  fi
}


# waffles.pushd is an alias for exec.mute pushd
function waffles.pushd {
  if [[ $# -eq 1 ]]; then
    exec.mute pushd $1
  fi
}

# waffles.popd is an alias for exec.mute popd
function waffles.popd {
  if [[ $# -eq 1 ]]; then
    exec.mute popd $1
  fi
}
