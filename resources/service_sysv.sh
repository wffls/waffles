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
# * name: The name of the service. Required. namevar.
#
# === Example
#
# ```shell
# service.sysv --name memcached
# ```
#
function service.sysv {

  # Resource Options
  local -A options
  waffles.options.create_option state "running"
  waffles.options.create_option name  "__required__"
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi


  # Process the resource
  waffles.resource.process "service.sysv" "${options[name]}"
}

function service.sysv.read {
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

function service.sysv.create {
  exec.capture_error /etc/init.d/${options[name]} start
}

function service.sysv.update {
  exec.capture_error /etc/init.d/${options[name]} restart
}

function service.sysv.delete {
  exec.capture_error /etc/init.d/${options[name]} stop
}
