# == Name
#
# service.sysv
#
# === Description
#
# Manages sysv-init services
#
# === Parameters
#
# * state: The state of the service. Required. Default: running.
# * name: The name of the service. Required.
#
# === Example
#
# ```bash
# service.sysv --name memcached
# ```
#
service.sysv() {
  # Declare the resource
  waffles_resource="service.sysv"

  # Resource Options
  local -A options
  waffles.options.create_option state "running"
  waffles.options.create_option name  "__required__"
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi


  # Process the resource
  waffles.resource.process $waffles_resource "${options[name]}"
}

service.sysv.read() {
  local _wrcs=""
  if [[ ! -f "/etc/init.d/${options[name]}" ]]; then
    log.error "/etc/init.d/${options[name]} does not exist."
    return 2
  else
    exec.mute /etc/init.d/${options[name]} status || {
      _wrcs="absent"
    }
  fi

  if [[ -z $_wrcs ]]; then
    _wrcs="present"
  fi

  waffles_resource_current_state="$_wrcs"
}

service.sysv.create() {
  exec.capture_error /etc/init.d/${options[name]} start
}

service.sysv.update() {
  exec.capture_error /etc/init.d/${options[name]} restart
}

service.sysv.delete() {
  exec.capture_error /etc/init.d/${options[name]} stop
}
