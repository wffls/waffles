# == Name
#
# rabbitmq.policy
#
# === Description
#
# Manages RabbitMQ policies
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the policy. Required. namevar.
# * vhost: The vhost to apply the policy to. Default: /.
# * queues: The queues to apply the policy to. Default: all.
# * policy: The policy. Required.
#
# === Example
#
# ```shell
# rabbitmq.policy --name openstack-ha --vhost openstack --policy '{"ha-mode":"all"}'
# ```
#
function rabbitmq.policy {
  stdlib.subtitle "rabbitmq.policy"

  # Resource Options
  local -A options
  stdlib.options.create_option state  "present"
  stdlib.options.create_option name   "__required__"
  stdlib.options.create_option vhost  "/"
  stdlib.options.create_option queues ""
  stdlib.options.create_option policy "__required__"
  stdlib.options.parse_options "$@"

  # Local Variables
  local queues
  local policy

  # Process the resource
  stdlib.resource.process "rabbitmq.policy" "${options[name]}"
}

function rabbitmq.policy.read {

  local _policy=$(rabbitmqctl -q list_policies -p ${options[vhost]} 2>/dev/null | grep ${options[name]})
  if [[ -z $_policy ]]; then
    stdlib_current_state="absent"
    return
  fi

  local _queue_set=$(echo "$_policy" | awk '{print $6}')
  if [[ -n $_queue_set ]]; then
    queues=$(echo "$_policy" | awk '{print $4}' | sed -e 's/[\/&]/\\&/g')
    policy=$(echo "$_policy" | awk '{print $5}')
  else
    queues=""
    policy=$(echo "$_policy" | awk '{print $4}')
  fi

  if [[ $queues != ${options[queues]} ]]; then
    stdlib_current_state="update"
    return
  fi

  if [[ $policy != ${options[policy]} ]]; then
    stdlib_current_state="update"
    return
  fi

  stdlib_current_state="present"
}

function rabbitmq.policy.create {
  stdlib.capture_error "rabbitmqctl set_policy -p ${options[vhost]} ${options[name]} '${options[queues]}' '${options[policy]}'"
}

function rabbitmq.policy.update {
  rabbitmq.policy.create
}

function rabbitmq.policy.delete {
  stdlib.capture_error "rabbitmqctl clear_policy -p ${options[vhost]} ${options[name]}"
}
