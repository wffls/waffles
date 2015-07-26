# == Name
#
# stdlib.upstart
#
# === Description
#
# Manages upstart services
#
# === Parameters
#
# * state: The state of the service. Required. Default: running.
# * name: The name of the service. Required. namevar.
#
# === Example
#
# ```shell
# stdlib.upstart --name memcached
# ```
#
function stdlib.upstart {
  stdlib.subtitle $FUNCNAME

  # Resource Options
  local -A options
  stdlib.options.create_option state "running"
  stdlib.options.create_option name  "__required__"
  stdlib.options.parse_options "$@"

  # Process the resource
  stdlib.resource.process "stdlib.upstart" "${options[name]}"
}

function stdlib.upstart.read {
  if [[ ! -f "/etc/init/${options[name]}.conf" ]]; then
    stdlib.error "/etc/init/${options[name]}.conf does not exist."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  else
    local _status=$(status ${options[name]})
    if [[ $_status =~ "stop" ]]; then
      stdlib_current_state="absent"
      return
    fi
  fi

  stdlib_current_state="present"
}

function stdlib.upstart.create {
  stdlib.capture_error start ${options[name]}
}

function stdlib.upstart.update {
  stdlib.capture_error restart ${options[name]}
}

function stdlib.upstart.delete {
  stdlib.capture_error stop {$options[name]}
}
