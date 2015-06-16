# == Name
#
# sysvinit
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
# stdlib.sysvinit --name memcached
#
function stdlib.sysvinit {
  stdlib.subtitle $FUNCNAME

  local -A options
  stdlib.options.set_option state "running"
  stdlib.options.set_option name  "__required__"
  stdlib.options.parse_options "$@"

  stdlib.catalog.add "stdlib.sysvinit/${options[name]}"

  stdlib.sysvinit.read
  if [[ ${options[state]} == stopped ]]; then
    if [[ $stdlib_current_state != stopped ]]; then
      stdlib.info "${options[name]} state: $stdlib_current_state, should be stopped."
      stdlib.sysvinit.delete
    fi
  else
    case "$stdlib_current_state" in
      stopped)
        stdlib.info "${options[name]} state: stopped, should be running."
        stdlib.sysvinit.create
        ;;
      running)
        stdlib.debug "${options[name]} state: running."
        ;;
    esac
  fi
}

function stdlib.sysvinit.read {
  if [[ ! -f /etc/init.d/${options[name]} ]]; then
    stdlib.error "/etc/init.d/${options[name]} does not exist."
    if [[ $WAFFLES_EXIT_ON_ERROR == true ]]; then
      exit 1
    else
      return 1
    fi
  else
    stdlib.debug_mute /etc/init.d/${options[name]} status
    if [[ $? != 0 ]]; then
      stdlib_current_state="stopped"
      return
    fi
  fi

  stdlib_current_state="running"
}

function stdlib.sysvinit.create {
  stdlib.capture_error /etc/init.d/${options[name]} start

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function stdlib.sysvinit.update {
  stdlib.capture_error /etc/init.d/${options[name]} restart

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function stdlib.sysvinit.delete {
  stdlib.info "Stopping ${options[name]}"

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}
