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
  if [[ ! -f "/etc/init.d/${options[name]}" ]]; then
    log.error "/etc/init.d/${options[name]} does not exist."
    return 1
  else
    exec.mute /etc/init.d/${options[name]} status
    if [[ $? != 0 ]]; then
      waffles_resource_current_state="absent"
      return
    fi
  fi

  waffles_resource_current_state="present"
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
