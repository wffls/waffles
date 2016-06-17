# == Name
#
# service.upstart
#
# === Description
#
# Manages upstart services
#
# === Parameters
#
# * state: The state of the service. Required. Default: running.
# * name: The name of the service. Required.
#
# === Example
#
# ```shell
# service.upstart --name memcached
# ```
#
function service.upstart {

  # Resource Options
  local -A options
  waffles.options.create_option state "running"
  waffles.options.create_option name  "__required__"
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi


  # Process the resource
  waffles.resource.process "service.upstart" "${options[name]}"
}

function service.upstart.read {
  if [[ ! -f "/etc/init/${options[name]}.conf" ]]; then
    log.error "/etc/init/${options[name]}.conf does not exist."
    waffles_resource_current_state="error"
    return
  else
    local _status=$(status ${options[name]})
    if [[ $_status =~ "stop" ]]; then
      waffles_resource_current_state="stopped"
      return
    fi
  fi

  waffles_resource_current_state="running"
}

function service.upstart.create {
  exec.capture_error start ${options[name]}
}

function service.upstart.update {
  exec.capture_error restart ${options[name]}
}

function service.upstart.delete {
  exec.capture_error stop ${options[name]}
}
