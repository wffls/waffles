# == Name
#
# rabbitmq.vhost
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
# ```shell
# rabbitmq.vhost --vhost openstack
# ```
#
function rabbitmq.vhost {
  stdlib.subtitle "rabbitmq.vhost"

  # Resource Options
  local -A options
  stdlib.options.create_option state  "present"
  stdlib.options.create_option vhost  "__required__"
  stdlib.options.parse_options "$@"

  # Process the resource
  stdlib.resource.process "rabbitmq.vhost" "${options[vhost]}"
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
}

function rabbitmq.vhost.delete {
  stdlib.capture_error "rabbitmqctl delete_vhost ${options[vhost]}"
}
