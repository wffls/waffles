# == Name
#
# apt.key
#
# === Description
#
# Manages apt keys
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: An arbitrary name. Required.
# * key: The key to import. Required if no remote_keyfile.
# * keyserver: The key server. Required if no remote_keyfile.
# * remote_keyfile: A remote key to import. Required if no key or keyserver.
#
# === Example
#
# ```bash
# apt.key --name "foobar" --key 1C4CBDCDCD2EFD2A
# ```
#
apt.key() {

  # Declare the resource title
  waffles_resource="apt.key"

  # Check if all dependencies are installed
  local _wrd=("wget" "apt-key" "grep" "curl" "gpg")
  if ! waffles.resource.check_dependencies "${_wrd[@]}" ; then
    return 2
  fi

  # Resource Options
  local -A options
  waffles.options.create_option state "present"
  waffles.options.create_option name  "__required__"
  waffles.options.create_option key
  waffles.options.create_option keyserver
  waffles.options.create_option remote_keyfile
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi

  # Local Variables
  local _key=""
  local _fingerprint=""

  # Process the resource
  waffles.resource.process $waffles_resource "${options[name]}"
}

apt.key.read() {
  local _exported=""
  local _waffles_resource_current_state="absent"

  if [[ -n ${options[remote_keyfile]} ]]; then
    _key=$(apt.key.get_remote_keyfile "${options[remote_keyfile]}")
    _fingerprint=$(apt.key.get_fingerprint_from_key "$_key")
    if [[ -n $_fingerprint ]]; then
      _exported=$(apt-key export $_fingerprint 2>/dev/null) || true
      if [[ -n $_exported ]]; then
        _waffles_resource_current_state="present"
      fi
    fi
  else
    _key=$(apt-key export ${options[key]} 2>/dev/null) || {
      _waffles_resource_current_state="absent"
    }

    if [[ $_key =~ "BEGIN PGP" ]]; then
      _waffles_resource_current_state="present"
    fi
  fi

  waffles_resource_current_state="$_waffles_resource_current_state"
}

apt.key.create() {
  if [[ -n ${options[remote_keyfile]} ]]; then
    exec.capture_error "echo \"$_key\" | apt-key add -"
  else
    exec.capture_error apt-key adv --keyserver ${options[keyserver]} --recv-keys ${options[key]}
  fi
}

apt.key.delete() {
  if [[ -n ${options[remote_keyfile]} ]]; then
    exec.capture_error apt-key del "$_fingerprint"
  else
    exec.capture_error apt-key del ${options[key]}
  fi
}

apt.key.get_remote_keyfile() {
  local _key=""
  if [[ $# -eq 1 ]]; then
    _key=$(curl -s "$1") || true
  fi

  echo "$_key"
}

apt.key.get_fingerprint_from_key() {
  local _fingerprint=""
  if [[ $# -eq 1 ]]; then
    _fingerprint=$(echo "$1" | gpg --with-fingerprint 2>/dev/null | grep ^pub | cut -d/ -f2 | cut -d" " -f1) || true
  fi

  echo "$_fingerprint"
}
