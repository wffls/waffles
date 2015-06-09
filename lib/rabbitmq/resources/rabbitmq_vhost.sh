# == Name
#
# vhost
#
# === Description
#
# Manages RabbitMQ vhosts
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * vhost: The vhostname of the rabbitmq vhost. Required. namevar.
#
# === Example
#
# rabbitmq.vhost --vhost openstack
#
function rabbitmq.vhost {
  stdlib.subtitle "rabbitmq.vhost"

  local -A options
  stdlib.options.set_option state  "present"
  stdlib.options.set_option vhost  "__required__"
  stdlib.options.parse_options "$@"

  stdlib.catalog.add "rabbitmq.vhost|${options[vhost]}"

  rabbitmq.vhost.read
  if [[ ${options[state]} == absent ]]; then
    if [[ $stdlib_current_state != absent ]]; then
      stdlib.info "${options[vhost]} state: $stdlib_current_state, should be absent."
      rabbitmq.vhost.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "${options[vhost]} state: absent, should be present."
        rabbitmq.vhost.create
        ;;
      present)
        stdlib.debug "${options[vhost]} state: present."
        ;;
    esac
  fi
}

function rabbitmq.vhost.read {

  rabbitmqctl -q list_vhosts 2>/dev/null | grep -q ${options[vhost]}
  if [[ $? == 1 ]]; then
    stdlib_current_state="absent"
    return
  fi

  stdlib_current_state="present"
}

function rabbitmq.vhost.create {
  stdlib.capture_error "rabbitmqctl add_vhost ${options[vhost]}"

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function rabbitmq.vhost.delete {
  stdlib.capture_error "rabbitmqctl delete_vhost ${options[vhost]}"

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}
