# == Name
#
# rabbitmq.user_permissions
#
# === Description
#
# Manages RabbitMQ user permissions
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * user: The username@vhost of the rabbitmq user. Required.
# * conf: The conf portion of the set_permissions command. Default: '.*'
# * write: The write portion of the set_permissions command. Default: '.*'
# * read: The read portion of the set_permissions command. Default: '.*'
#
# === Example
#
# ```shell
# rabbitmq.user_permission --user_permission root --password password
# ```
#
rabbitmq.user_permissions() {
  # Declare the resource
  waffles_resource="rabbitmq.user_permissions"

  # Resource Options
  local -A options
  waffles.options.create_option state  "present"
  waffles.options.create_option user   "__required__"
  waffles.options.create_option conf   '.*'
  waffles.options.create_option write  '.*'
  waffles.options.create_option read   '.*'
  waffles.options.parse_options "$@"

  # Local Variables
  string.split "${options[user]}" '@'
  local _user="${__split[0]}"
  local _vhost="${__split[1]}"
  local _conf
  local _write
  local _read

  # Internal Resource Configuration
  if [[ -z $_vhost ]]; then
    log.warn "user must be in the format of user@vhost. Defaulting to / for vhost."
    _vhost="/"
  fi

  # Process the resource
  waffles.resource.process $waffles_resource "${options[user]}"
}

rabbitmq.user_permissions.read() {

  local _permissions=$(rabbitmqctl -q list_permissions -p $_vhost 2>/dev/null | grep $_user)
  if [[ -z $_permissions ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  _conf=$(echo "$_permissions" | awk '{print $2}')
  if [[ ${options[conf]} != $_conf ]]; then
    waffles_resource_current_state="update"
    return
  fi

  _write=$(echo "$_permissions" | awk '{print $3}')
  if [[ ${options[write]} != $_write ]]; then
    waffles_resource_current_state="update"
    return
  fi

  _read=$(echo "$_permissions" | awk '{print $4}')
  if [[ ${options[read]} != $_read ]]; then
    waffles_resource_current_state="update"
    return
  fi

  waffles_resource_current_state="present"
}

rabbitmq.user_permissions.create() {
  exec.capture_error "rabbitmqctl set_permissions -p $_vhost $_user '${options[conf]}' '${options[write]}' '${options[read]}'"
}

rabbitmq.user_permissions.update() {
  rabbitmq.user_permissions.create
}

rabbitmq.user_permissions.delete() {
  exec.capture_error "rabbitmqctl clear_permissions -p $_vhost $_user"
}
