# == Name
#
# service.systemd
#
# === Description
#
# Manages systemd services
#
# === Parameters
#
# * state: State of the service. Required. Default: running.
# * name: Name of the service. Do not include the ".service" suffix. Required.
# * enabled: Start service at boot, true or false. Optional.
#
# === Example
#
# ```bash
# service.systemd --name memcached
# ```
#
service.systemd() {
  # Declare the resource
  waffles_resource="service.systemd"

  # Check if all dependencies are installed
  local _wrd=("systemctl grep")
  if ! waffles.resource.check_dependencies "${_wrd[@]}" ; then
    return 1
  fi

  # Resource Options
  local -A options
  waffles.options.create_option state "running"
  waffles.options.create_option name  "__required__"
  waffles.options.create_option enabled ""
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi

  # Check syntax of enabled option
  if [[ -n "${options[enabled]}" ]] && ! waffles.options.is_bool "${options[enabled]}"; then
    log.error "--enabled '${options[enabled]}': must be empty, 'true' or 'false'."
    return 1
  fi

  # Process the resource
  waffles.resource.process $waffles_resource "${options[name]}"
}

service.systemd.read() {
  # Check if service exists
  local _service_exists=$(systemctl list-unit-files -t service --no-legend | grep "^${options[name]}.service") || :
  if [[ -z ${_service_exists} ]]; then
    log.error "service ${options[name]} does not exist."
    waffles_resource_current_state="error"
    return
  fi

  # Get the resource state
  if systemctl -q is-active ${options[name]}; then
    waffles_resource_current_state="running"
  else
    waffles_resource_current_state="stopped"
  fi

  # Get the enabled state, if requested
  if [[ -n ${options[enabled]} ]]; then
    if systemctl -q is-enabled ${options[name]} && [[ ${options[enabled]} == "false" ]]; then
        log.debug "${options[name]} is enabled but should be disabled"
        waffles_resource_current_state="update"
    fi

    if ! systemctl -q is-enabled ${options[name]} && [[ ${options[enabled]} == "true" ]]; then
        log.debug "${options[name]} is disabled but should be enabled"
        waffles_resource_current_state="update"
    fi
  fi
}

service.systemd.create() {
  service.systemd.update
}
service.systemd.update() {
  if [[ -n ${options[enabled]} ]]; then
    if [[ ${options[enabled]} == "true" ]]; then
      exec.capture_error systemctl enable ${options[name]}
    else
      exec.capture_error systemctl disable ${options[name]}
    fi
  fi

  if systemctl -q is-active ${options[name]} && [[ ${options[state]} != "running" ]]; then
    exec.capture_error systemctl stop ${options[name]}
  elif ! systemctl -q is-active ${options[name]} && [[ ${options[state]} != "stopped" ]]; then
    exec.capture_error systemctl start ${options[name]}
  fi
}
service.systemd.delete() {
  service.systemd.update
}
