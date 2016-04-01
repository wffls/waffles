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
  waffles.subtitle "keepalived.global_defs"

  if ! waffles.command_exists augtool ; then
    log.error "Cannot find augtool."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  local -a notification_email
  local -a simple_options=("notification_email_from" "smtp_server"
                           "smtp_connect_timeout" "router_id"
                           "vrrp_mcast_group4" "vrrp_mcast_group6")

  waffles.options.create_option    state "present"
  waffles.options.create_mv_option notification_email
  waffles.options.create_option    file  "/etc/keepalived/keepalived.conf"

  # Quickly make all of the simple options
  for o in "${simple_options[@]}"; do
    waffles.options.create_option    $o
  done

  waffles.options.parse_options    "$@"

  # Local Variables
  local -A options_to_update
  local _name="keepalived.global_defs"
  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"

  # Process the resource
  waffles.resource.process "keepalived.global_defs" "$_name"
}

function keepalived.global_defs.read {
  if [[ ! -f $_file ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  # Check if the global_defs key exists
  waffles_resource_current_state=$(augeas.get --lens Keepalived --file "$_file" --path "/global_defs")
  if [[ $waffles_resource_current_state == "absent" ]]; then
    return
  fi

  # Check if the notification emails exist
  for n in "${notification_email[@]}"; do
    _result=$(augeas.get --lens Keepalived --file "$_file" --path "/global_defs/notification_email/email[. = '$n']")
    if [[ $_result == "absent" ]]; then
      waffles_resource_current_state="update"
      options_to_update["notification_email"]=1
    fi
  done

  # Check if the other keys are set
  for o in "${simple_options[@]}"; do
    if [[ -n ${options[$o]} ]]; then
      _result=$(augeas.get --lens Keepalived --file "$_file" --path "/global_defs/${o}[. = '${options[$o]}']")
      if [[ $_result == "absent" ]]; then
        waffles_resource_current_state="update"
        options_to_update[$o]=1
      fi
    fi
  done

  if [[ "$waffles_resource_current_state" == "update" ]]; then
    return
  else
    waffles_resource_current_state="present"
  fi

}

function keepalived.global_defs.create {
  local _result
  local -a _augeas_commands=()

  if [[ ! -d $_dir ]]; then
    exec.capture_error mkdir -p "$_dir"
  fi

  # Set notification emails
  if [[ ${options_to_update[notification_email]+isset} ]]; then
    for n in "${notification_email[@]}"; do
      _augeas_commands+=("set /files/${_file}/global_defs/notification_email/email[0] '$n'")
    done
  fi

  # Set all other options
  for o in "${!options_to_update[@]}"; do
    if [[ $o == "notification_email" ]]; then
      continue
    fi
    if [[ -n ${options[$o]} ]]; then
      _augeas_commands+=("set /files/${_file}/global_defs/$o '${options[$o]}'")
    fi
  done

  _result=$(augeas.run --lens Keepalived --file "$_file" "${_augeas_commands[@]}")
  if [[ $_result =~ ^error ]]; then
    log.error "Error adding $_name with augeas: $_result"
  fi
}

function keepalived.global_defs.update {
  keepalived.global_defs.delete
  keepalived.global_defs.create
}

function keepalived.global_defs.delete {
  local _result
  local -a _augeas_commands=()

  # Delete notification emails
  if [[ ${options_to_update[notification_email]+isset} ]]; then
    _augeas_commands+=("rm /files/${_file}/global_defs/notification_email")
  fi

  # Set all other options
  for o in "${!options_to_update[@]}"; do
    if [[ $o == "notification_emails" ]]; then
      continue
    fi
    _augeas_commands+=("rm /files/${_file}/global_defs/$o")
  done

  _result=$(augeas.run --lens Keepalived --file "$_file" "${_augeas_commands[@]}")
  if [[ $_result =~ ^error ]]; then
    log.error "Error adding $_name with augeas: $_result"
  fi
}
