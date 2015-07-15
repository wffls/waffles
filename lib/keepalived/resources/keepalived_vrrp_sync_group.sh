# == Name
#
# keepalived.vrrp_sync_group
#
# === Description
#
# Manages vrrp_sync_group section in keepalived.conf
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the VRRP instance. Required. namevar.
# * group: The name of a VRRP instance. Required. Multi-var.
# * file: The file to store the settings in. Required. Defaults to /etc/keepalived/keepalived.conf.
#
# === Example
#
# ```shell
# keepalived.vrrp_sync_group --name VSG_1 \
#                            --group VI_1 \
#                            --group VI_2 \
# ```
#
function keepalived.vrrp_sync_group {
  stdlib.subtitle "keepalived.vrrp_sync_group"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  local -a group
  stdlib.options.create_option state    "present"
  stdlib.options.create_option name     "__required__"
  stdlib.options.create_option file     "/etc/keepalived/keepalived.conf"
  stdlib.options.create_mv_option group "__required__"
  stdlib.options.parse_options    "$@"

  local _name="${options[name]}"
  stdlib.catalog.add "keepalived.vrrp_sync_group/${options[name]}"

  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"
  local -A options_to_update

  # a list of "simple" key/value options
  local -a simple_options=("notify_master" "notify_backup" "notify_fault" "notify")

  # boolean options
  local -a boolean_options=("smtp_alert")

  keepalived.vrrp_sync_group.read
  if [[ "${options[state]}" == "absent" ]]; then
    if [[ "$stdlib_current_state" != "absent" ]]; then
      stdlib.info "$_name state: $stdlib_current_state, should be absent."
      keepalived.vrrp_sync_group.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "$_name state: absent, should be present."
        keepalived.vrrp_sync_group.create
        ;;
      present)
        stdlib.debug "$_name state: present."
        ;;
      update)
        stdlib.info "$_name state: present, needs updated."
        keepalived.vrrp_sync_group.delete
        keepalived.vrrp_sync_group.create
        ;;
    esac
  fi
}

function keepalived.vrrp_sync_group.read {
  if [[ ! -f "$_file" ]]; then
    stdlib_current_state="absent"
    return
  fi

  # Check if the vrrp_sync_group exists
  stdlib_current_state=$(augeas.get --lens Keepalived --file "$_file" --path "/vrrp_sync_group[. = '${options[name]}']")
  if [[ "$stdlib_current_state" == "absent" ]]; then
    return
  fi

  # Check if the groups exist
  for g in "${group[@]}"; do
    _result=$(augeas.get --lens Keepalived --file "$_file" --path "/vrrp_sync_group[. = '${options[name]}']/group/$g")
    if [[ "$_result" == "absent" ]]; then
      options_to_update["group"]=1
      stdlib_current_state="update"
    fi
  done

  if [[ "$stdlib_current_state" == "update" ]]; then
    return
  else
    stdlib_current_state="present"
  fi

}

function keepalived.vrrp_sync_group.create {
  local _result
  local -a _augeas_commands=()

  if [[ ! -d "$_dir" ]]; then
    stdlib.capture_error mkdir -p "$_dir"
  fi

  # Create the vrrp_sync_group
  if [[ "$stdlib_current_state" == "absent" ]]; then
    _augeas_commands+=("set /files/${_file}/vrrp_sync_group[0] '${options[name]}'")
  fi

  # Set groups
  if [[ "${options_to_update[group]+isset}" || "$stdlib_current_state" == "absent" ]]; then
    for g in "${group[@]}"; do
      _augeas_commands+=("touch /files/${_file}/vrrp_sync_group[. = '${options[name]}']/group/$g")
    done
  fi

  _result=$(augeas.run --lens Keepalived --file "$_file" "${_augeas_commands[@]}")
  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
  fi
}

function keepalived.vrrp_sync_group.delete {
  local _result
  local -a _augeas_commands=()

  # Delete groups
  if [[ "${options_to_update[virtual_ipaddress]+isset}" ]]; then
    for n in "${virtual_ipaddress[@]}"; do
      _augeas_commands+=("rm /files/${_file}/vrrp_sync_group[. = '${options[name]}']/group")
    done
  fi

  _result=$(augeas.run --lens Keepalived --file "$_file" "${_augeas_commands[@]}")
  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
  fi
}
