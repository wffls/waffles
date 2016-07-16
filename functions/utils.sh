# These commands are simple helpers to detect how Waffles was run.
waffles.noop() {
  [[ -n ${WAFFLES_NOOP:-} ]]
}

waffles.debug() {
  [[ -n ${WAFFLES_DEBUG:-} ]]
}

# waffles.include is a more intelligent "source".
# It will warn if the file does not exist, rather than erroring.
waffles.include() {
  if [[ $# -gt 0 ]]; then
    if [[ -f $1 ]]; then
      source -- "$1"
    else
      log.warn "File not found: $1"
    fi
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
waffles.build_ini_file() {
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

# waffles.dir is a clean way of getting the current dir of the script being run.
waffles.dir() {
  if [[ $# -gt 0 ]]; then
    echo $(readlink -f "${1%/*}")
  fi
}

# waffles.command_exists is a simple alias for `which`
waffles.command_exists() {
  which $1 &>/dev/null
}

# waffles.pushd is an alias for exec.mute pushd
waffles.pushd() {
  if [[ $# -eq 1 ]]; then
    exec.mute pushd $1
  fi
}

# waffles.popd is an alias for exec.mute popd
waffles.popd() {
  if [[ $# -eq 1 ]]; then
    exec.mute popd $1
  fi
}
