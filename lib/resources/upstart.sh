# == Name
#
# upstart
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
# stdlib.upstart --name memcached
#
function stdlib.upstart {
  stdlib.subtitle $FUNCNAME

  local -A options
  stdlib.options.set_option state "running"
  stdlib.options.set_option name  "__required__"
  stdlib.options.parse_options "$@"

  stdlib.catalog.add "stdlib.upstart/${options[name]}"

  stdlib.upstart.read
  if [[ ${options[state]} == stopped ]]; then
    if [[ $stdlib_current_state != stopped ]]; then
      stdlib.info "${options[name]} state: $stdlib_current_state, should be stopped."
      stdlib.upstart.delete
    fi
  else
    case "$stdlib_current_state" in
      stopped)
        stdlib.info "${options[name]} state: stopped, should be running."
        stdlib.upstart.create
        ;;
      running)
        stdlib.debug "${options[name]} state: running."
        ;;
    esac
  fi
}

function stdlib.upstart.read {
  if [[ ! -f /etc/init/${options[name]}.conf ]]; then
    stdlib.error "/etc/init/${options[name]}.conf does not exist."
    if [[ $WAFFLES_EXIT_ON_ERROR == true ]]; then
      exit 1
    else
      return 1
    fi
  else
    local _status=$(status ${options[name]})
    if [[ $_status =~ stop ]]; then
      stdlib_current_state="stopped"
      return
    fi
  fi

  stdlib_current_state="running"
}

function stdlib.upstart.create {
  stdlib.capture_error start ${options[name]}

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function stdlib.upstart.update {
  stdlib.capture_error restart ${options[name]}

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function stdlib.upstart.delete {
  stdlib.capture_error stop {$options[name]}

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}
