# == Name
#
# stdlib.apt_key
#
# === Description
#
# Manages apt keys
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: An arbitrary name. Required. namevar.
# * key: The key to import. Required if no remote_keyfile.
# * keyserver: The key server. Required if no remote_keyfile.
# * remote_keyfile: A remote key to import. Required if no key or keyserver.
#
# === Example
#
# ```shell
# stdlib.apt_key --name "foobar" --key 1C4CBDCDCD2EFD2A
# ```
#
function stdlib.apt_key {
  stdlib.subtitle "stdlib.apt_key"

  # Resource Options
  local -A options
  stdlib.options.create_option state "present"
  stdlib.options.create_option name  "__required__"
  stdlib.options.create_option key
  stdlib.options.create_option keyserver
  stdlib.options.create_option remote_keyfile
  stdlib.options.parse_options "$@"

  # Process the resource
  stdlib.resource.process "stdlib.apt_key" "${options[name]}"
}

function stdlib.apt_key.read {
  apt-key export ${options[key]} 2>/dev/null | grep -q "BEGIN PGP"
  if [[ $? == 0 ]]; then
    stdlib_current_state="present"
    return
  fi
  stdlib_current_state="absent"
}

function stdlib.apt_key.create {
  if [[ -n ${options[remote_keyfile]} ]]; then
    if ! stdlib.command_exists wget ; then
      stdlib.error "wget not installed. Unable to obtain remote keyfile."
      if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
        exit 1
      else
        return 1
      fi
    else
      local _remote_file="${options[remote_keyfile]}"
      local _local_file=${_remote_file##*/}
      stdlib.mute pushd /tmp
      stdlib.capture_error wget "$_remote_file"
      stdlib.capture_error apt-key add "$_local_file"
      stdlib.mute rm "$_remote_file"
      stdlib.mute popd
    fi
  else
    stdlib.capture_error apt-key adv --keyserver ${options[keyserver]} --recv-keys ${options[key]}
  fi
}

function stdlib.apt_key.delete {
  stdlib.capture_error apt-key del ${options[key]}
}
