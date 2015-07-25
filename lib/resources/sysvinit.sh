# == Name
#
# stdlib.sysvinit
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
# stdlib.sysvinit --name memcached
# ```
#
function stdlib.sysvinit {
  stdlib.subtitle $FUNCNAME

  # Resource Options
  local -A options
  stdlib.options.create_option state "running"
  stdlib.options.create_option name  "__required__"
  stdlib.options.parse_options "$@"

  # Process the resource
  stdlib.resource.process "stdlib.sysvinit" "${options[name]}"
}

function stdlib.sysvinit.read {
  if [[ ! -f "/etc/init.d/${options[name]}" ]]; then
    stdlib.error "/etc/init.d/${options[name]} does not exist."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  else
    stdlib.debug_mute /etc/init.d/${options[name]} status
    if [[ $? != 0 ]]; then
      stdlib_current_state="absent"
      return
    fi
  fi

  stdlib_current_state="present"
}

function stdlib.sysvinit.create {
  stdlib.capture_error /etc/init.d/${options[name]} start
}

function stdlib.sysvinit.update {
  stdlib.capture_error /etc/init.d/${options[name]} restart
}

function stdlib.sysvinit.delete {
  stdlib.capture_error /etc/init.d/${options[name]} stop
}
