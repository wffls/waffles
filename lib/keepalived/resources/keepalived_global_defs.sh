# == Name
#
# keepalived.global_defs
#
# === Description
#
# Manages global_defs section in keepalived.conf
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * notification_email: Email address to send notifications. Optional. Multi-var.
# * notification_email_from: The From address on email notifications. Optional.
# * smtp_server: The smtp server to send notifications. Optional.
# * smtp_connect_timeout: Connect timeout for sending notifications. Optional.
# * router_id: The router ID. Optional.
# * vrrp_mcast_group4: VRRP multicast group for IPv4. Optional.
# * vrrp_mcast_group6: VRRP multicast group for IPv6. Optional.
# * file: The file to store the settings in. Optional. Defaults to /etc/keepalived/keepalived.conf.
#
# === Example
#
# ```shell
# keepalived.global_defs --notification_email root@localhost \
#                        --notification_email jdoe@example.com \
#                        --smtp_server smtp.example.com \
#                        --router_id 42
# ```
#
function keepalived.global_defs {
  stdlib.subtitle "keepalived.global_defs"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  local -a notification_email
  local -a simple_options=("notification_email_from" "smtp_server"
                           "smtp_connect_timeout" "router_id"
                           "vrrp_mcast_group4" "vrrp_mcast_group6")

  stdlib.options.create_option    state "present"
  stdlib.options.create_mv_option notification_email
  stdlib.options.create_option    file  "/etc/keepalived/keepalived.conf"

  # Quickly make all of the simple options
  for o in "${simple_options[@]}"; do
    stdlib.options.create_option    $o
  done

  stdlib.options.parse_options    "$@"

  local _name="keepalived.global_defs"
  stdlib.catalog.add "keepalived.global_defs"

  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"

  local -A options_to_update
  keepalived.global_defs.read
  if [[ "${options[state]}" == "absent" ]]; then
    if [[ "$stdlib_current_state" != "absent" ]]; then
      stdlib.info "$_name state: $stdlib_current_state, should be absent."
      keepalived.global_defs.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "$_name state: absent, should be present."
        keepalived.global_defs.create
        ;;
      present)
        stdlib.debug "$_name state: present."
        ;;
      update)
        stdlib.info "$_name state: present, needs updated."
        keepalived.global_defs.delete
        keepalived.global_defs.create
        ;;
    esac
  fi
}

function keepalived.global_defs.read {
  if [[ ! -f "$_file" ]]; then
    stdlib_current_state="absent"
    return
  fi

  # Check if the global_defs key exists
  stdlib_current_state=$(augeas.get --lens Keepalived --file "$_file" --path "/global_defs")
  if [[ "$stdlib_current_state" == "absent" ]]; then
    return
  fi

  # Check if the notification emails exist
  for n in "${notification_email[@]}"; do
    _result=$(augeas.get --lens Keepalived --file "$_file" --path "/global_defs/notification_email/email[. = '$n']")
    if [[ "$_result" == "absent" ]]; then
      stdlib_current_state="update"
      options_to_update["notification_email"]=1
    fi
  done

  # Check if the other keys are set
  for o in "${simple_options[@]}"; do
    if [[ -n "${options[$o]}" ]]; then
      _result=$(augeas.get --lens Keepalived --file "$_file" --path "/global_defs/${o}[. = '${options[$o]}']")
      if [[ "$_result" == "absent" ]]; then
        stdlib_current_state="update"
        options_to_update[$o]=1
      fi
    fi
  done

  if [[ "$stdlib_current_state" == "update" ]]; then
    return
  else
    stdlib_current_state="present"
  fi

}

function keepalived.global_defs.create {
  local _result
  local -a _augeas_commands=()

  if [[ ! -d "$_dir" ]]; then
    stdlib.capture_error mkdir -p "$_dir"
  fi

  # Set notification emails
  if [[ "${options_to_update[notification_email]+isset}" ]]; then
    for n in "${notification_email[@]}"; do
      _augeas_commands+=("set /files/${_file}/global_defs/notification_email/email[0] '$n'")
    done
  fi

  # Set all other options
  for o in "${!options_to_update[@]}"; do
    if [[ "$o" == "notification_email" ]]; then
      continue
    fi
    if [[ -n "${options[$o]}" ]]; then
      _augeas_commands+=("set /files/${_file}/global_defs/$o '${options[$o]}'")
    fi
  done

  _result=$(augeas.run --lens Keepalived --file "$_file" "${_augeas_commands[@]}")
  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
  fi
}

function keepalived.global_defs.delete {
  local _result
  local -a _augeas_commands=()

  # Delete notification emails
  if [[ "${options_to_update[notification_email]+isset}" ]]; then
    _augeas_commands+=("rm /files/${_file}/global_defs/notification_email")
  fi

  # Set all other options
  for o in "${!options_to_update[@]}"; do
    if [[ "$o" == "notification_emails" ]]; then
      continue
    fi
    _augeas_commands+=("rm /files/${_file}/global_defs/$o")
  done

  _result=$(augeas.run --lens Keepalived --file "$_file" "${_augeas_commands[@]}")
  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
  fi
}
