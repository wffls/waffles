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
# * onboot: Whether the service should start at boot. Default: true.
# * daemon: The name of the service's running daemon. Optional. Defaults to name.
#
# === Example
#
# ```bash
# service.sysv --name memcached --onboot false
# ```
#
# === Notes
#
# * Waffles expects an /etc/init.d script to exist prior to running this resource.
# * This is only compatible with Debian-based systems at the moment.
#
service.sysv() {
  # Declare the resource
  waffles_resource="service.sysv"

  # Check if all dependencies are installed
  local _wrd("pidof" "update-rc.d")
  if ! waffles.resource.check_dependencies "${_wrd[@]}" ; then
    return 1
  fi

  # Resource Options
  local -A options
  waffles.options.create_option state  "running"
  waffles.options.create_option name   "__required__"
  waffles.options.create_option onboot true
  waffles.options.create_option daemon
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi

  # Local variables
  local _daemon
  local _pid
  local _rc_entries

  # Internal Resource Configuration
  # If a daemon name wasn't given, use the service name.
  if [[ -n ${options[daemon]} ]]; then
    _daemon="${options[daemon]}"
  else
    _daemon="${options[name]}"
  fi

  # Process the resource
  waffles.resource.process $waffles_resource "${options[name]}"
}

service.sysv.read() {
  local _current_state

  # First, check if the init script exists.
  # The init script is a requirement.
  # Waffles will not manage service execution directly.
  if [[ ! -f "/etc/init.d/${options[name]}" ]]; then
    log.error "/etc/init.d/${options[name]} does not exist."
    return 1
  fi

  # Get the number of "start" rc entries for the service.
  _rc_entries=($(ls /etc/rc*.d/S??${options[name]}))

  # Get the pid(s) of the running service (if any)
  _pid=$(pidof $_daemon)

  # Check if the service is running by the results of the pid(s).
  # Can't trust /etc/init.d/service status since some init scripts
  # don't implement it.
  if [[ -z $_pid ]]; then
    _current_state="stopped"

  # Next, check if the service should start at boot
  elif [[ ${options[onboot]} == "true" ]]; then
    if [[ ${#_rc_entries[@]} -lt 4 ]]; then
      _current_state="update"
    fi

  # Next, check if the service should not start at boot
  elif [[ ${options[onboot]} == "false" ]]; then
    if [[ ${#_rc_entries[@]} -ge 4 ]]; then
      _current_state="update"
    fi
  fi

  if [[ -n $_current_state ]]; then
    waffles_resource_current_state="$_current_state"
  else
    waffles_resource_current_state="present"
  fi
}

service.sysv.create() {
  # All roads point to update() for services
  service.sysv.update()
}

service.sysv.update() {
  # Make sure the rc links are in place (or not)
  service.sysv.debian.handle_boot

  # Start the service if it's not running.
  # If you need to "kick" the service, do it another way.
  service.sysv.debian.handle_service
}

service.sysv.delete() {
  # All roads point to update() for services
  service.sysv.update()
}

# Helper functions

service.sysv.debian.handle_boot() {
  exec.capture_error update-rc.d -f "${options[name]}" remove
  if [[ ${options[onboot]} == "true" ]]; then
    exec.capture_error update-rc.d "${options[name]}" defaults
  fi
}

service.sysv.debian.handle_service() {
  if [[ ${options[state]} == "running" ]] && [[ -z $_pid ]]; then
    exec.capture_error /etc/init.d/${options[name]} start
  fi

  if [[ ${options[state]} == "stopped" ]] && [[ -n $_pid ]]; then
    exec.capture_error /etc/init.d/${options[name]} stop
  fi
}
