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
  waffles.subtitle "rabbitmq.vhost"

  # Resource Options
  local -A options
  waffles.options.create_option state  "present"
  waffles.options.create_option vhost  "__required__"
  waffles.options.parse_options "$@"

  # Process the resource
  waffles.resource.process "rabbitmq.vhost" "${options[vhost]}"
}

function rabbitmq.vhost.read {

  rabbitmqctl -q list_vhosts 2>/dev/null | grep -q ${options[vhost]}
  if [[ $? == 1 ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  waffles_resource_current_state="present"
}

function rabbitmq.vhost.create {
  exec.capture_error "rabbitmqctl add_vhost ${options[vhost]}"
}

function rabbitmq.vhost.delete {
  exec.capture_error "rabbitmqctl delete_vhost ${options[vhost]}"
}
