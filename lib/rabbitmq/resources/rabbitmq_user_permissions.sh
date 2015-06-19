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
# * user: The username@vhost of the rabbitmq user. Required. namevar.
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
function rabbitmq.user_permissions {
  stdlib.subtitle "rabbitmq.user_permissions"

  local -A options
  stdlib.options.set_option state  "present"
  stdlib.options.set_option user   "__required__"
  stdlib.options.set_option conf   '.*'
  stdlib.options.set_option write  '.*'
  stdlib.options.set_option read   '.*'
  stdlib.options.parse_options "$@"

  stdlib.catalog.add "rabbitmq.user_permissions|${options[user]}"

  stdlib.split "${options[user]}" '@'
  local _user="${__split[0]}"
  local _vhost="${__split[1]}"
  local _conf
  local _write
  local _read

  if [[ -z $_vhost ]]; then
    stdlib.warn "user must be in the format of user@vhost. Defaulting to / for vhost."
    _vhost="/"
  fi

  rabbitmq.user_permissions.read
  if [[ ${options[state]} == absent ]]; then
    if [[ $stdlib_current_state != absent ]]; then
      stdlib.info "${options[user]} state: $stdlib_current_state, should be absent."
      rabbitmq.user_permissions.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "${options[user]} state: absent, should be present."
        rabbitmq.user_permissions.create
        ;;
      present)
        stdlib.debug "${options[user]} state: present."
        ;;
      update)
        stdlib.debug "${options[user]} state: out of date."
        rabbitmq.user_permissions.create
        ;;
    esac
  fi
}

function rabbitmq.user_permissions.read {

  local _permissions=$(rabbitmqctl -q list_permissions -p $_vhost 2>/dev/null | grep $_user)
  if [[ -z $_permissions ]]; then
    stdlib_current_state="absent"
    return
  fi

  _conf=$(echo "$_permissions" | awk '{print $2}')
  if [[ ${options[conf]} != $_conf ]]; then
    stdlib_current_state="update"
    return
  fi

  _write=$(echo "$_permissions" | awk '{print $3}')
  if [[ ${options[write]} != $_write ]]; then
    stdlib_current_state="update"
    return
  fi

  _read=$(echo "$_permissions" | awk '{print $4}')
  if [[ ${options[read]} != $_read ]]; then
    stdlib_current_state="update"
    return
  fi

  stdlib_current_state="present"
}

function rabbitmq.user_permissions.create {
  stdlib.capture_error "rabbitmqctl set_permissions -p $_vhost $_user '${options[conf]}' '${options[write]}' '${options[read]}'"

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function rabbitmq.user_permissions.delete {
  stdlib.capture_error "rabbitmqctl clear_permissions -p $_vhost $_user"

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}
