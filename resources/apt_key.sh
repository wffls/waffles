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
# ```shell
# apt.key --name "foobar" --key 1C4CBDCDCD2EFD2A
# ```
#
apt.key() {

  # Declare the resource title
  waffles_resource="apt.key"

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

  # Process the resource
  waffles.resource.process $waffles_resource "${options[name]}"
}

apt.key.read() {
  apt-key export ${options[key]} 2>/dev/null | grep -q "BEGIN PGP"
  if [[ $? == 0 ]]; then
    waffles_resource_current_state="present"
    return
  fi
  waffles_resource_current_state="absent"
}

apt.key.create() {
  if [[ -n ${options[remote_keyfile]} ]]; then
    if ! waffles.command_exists wget ; then
      log.error "wget not installed. Unable to obtain remote keyfile."
      return 1
    else
      local _remote_file="${options[remote_keyfile]}"
      local _local_file=${_remote_file##*/}
      waffles.pushd /tmp
      exec.capture_error wget "$_remote_file"
      exec.capture_error apt-key add "$_local_file"
      exec.mute rm "$_remote_file"
      waffles.popd
    fi
  else
    exec.capture_error apt-key adv --keyserver ${options[keyserver]} --recv-keys ${options[key]}
  fi
}

apt.key.delete() {
  exec.capture_error apt-key del ${options[key]}
}
