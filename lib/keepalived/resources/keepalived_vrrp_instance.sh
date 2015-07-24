# == Name
#
# keepalived.vrrp_instance
#
# === Description
#
# Manages vrrp_instance section in keepalived.conf
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the VRRP instance. Required. namevar.
# * vrrp_state: The state of the VRRP instance. Required.
# * interface: The interface to monitor. Required.
# * virtual_router_id: The virtual router ID. Required.
# * priority: The priority. Required.
# * advert_int: The advert interval. Optional.
# * auth_type: The authentication type. Optional.
# * auth_pass: The authentication password. Optional.
# * virtual_ipaddress: A virtual IP address. Optional. Multi-var.
# * smtp_alert: Send an email during transition. Optional. Defaults to false.
# * unicast_src_ip: Source IP for unicast packets. Optional.
# * unicast_peer: A peer in a unicast group. Optional. Multi-var.
# * native_ipv6: Force IPv6. Optional. Defaults to false.
# * notify_master: The notify_master script. Optional.
# * notify_backup: The notify_backup script. Optional.
# * notify_fault: The notify_fault script. Optional.
# * notify: The notify script. Optional.
# * debug: Enable debugging. Optional. Defaults to false.
# * file: The file to store the settings in. Required. Defaults to /etc/keepalived/keepalived.conf.
#
# === Example
#
# ```shell
# keepalived.vrrp_instance --name VI_1 \
#                          --vrrp_state MASTER \
#                          --interface eth0 \
#                          --virtual_router_id 42 \
#                          --priority 100 \
#                          --virtual_ipaddress 192.168.1.10
# ```
#
function keepalived.vrrp_instance {
  stdlib.subtitle "keepalived.vrrp_instance"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  local -a virtual_ipaddress
  local -a unicast_peer
  stdlib.options.create_option    state             "present"
  stdlib.options.create_option    name              "__required__"
  stdlib.options.create_option    vrrp_state        "__required__"
  stdlib.options.create_option    interface         "__required__"
  stdlib.options.create_option    virtual_router_id "__required__"
  stdlib.options.create_option    priority          "__required__"
  stdlib.options.create_option    file              "/etc/keepalived/keepalived.conf"
  stdlib.options.create_option    smtp_alert        "false"
  stdlib.options.create_option    native_ipv6       "false"
  stdlib.options.create_option    debug             "false"
  stdlib.options.create_option    advert_int
  stdlib.options.create_option    auth_type
  stdlib.options.create_option    auth_pass
  stdlib.options.create_option    unicast_src_ip
  stdlib.options.create_option    notify_master
  stdlib.options.create_option    notify_backup
  stdlib.options.create_option    notify_fault
  stdlib.options.create_option    notify
  stdlib.options.create_mv_option virtual_ipaddress
  stdlib.options.create_mv_option unicast_peer
  stdlib.options.parse_options    "$@"

  # If auth_type is set, make sure auth_pass is set
  if [[ -n "${options[auth_type]}" && -z "${options[auth_pass]}" ]]; then
    stdlib.error "Both auth_type and auth_pass must be set."
    return
  fi

  local _name="${options[name]}"
  stdlib.catalog.add "keepalived.vrrp_instance/${options[name]}"

  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"
  local -A options_to_update

  # a list of "simple" key/value options
  local -a simple_options=("interface" "virtual_router_id" "priority" "advert_int" "unicast_src_ip" "notify_master" "notify_backup" "notify_fault" "notify")

  # auth-related keys
  local -a auth_keys=("auth_type" "auth_pass")

  # boolean options
  local -a boolean_options=("smtp_alert" "native_ipv6" "debug")

  keepalived.vrrp_instance.read
  if [[ "${options[state]}" == "absent" ]]; then
    if [[ "$stdlib_current_state" != "absent" ]]; then
      stdlib.info "$_name state: $stdlib_current_state, should be absent."
      keepalived.vrrp_instance.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "$_name state: absent, should be present."
        keepalived.vrrp_instance.create
        ;;
      present)
        stdlib.debug "$_name state: present."
        ;;
      update)
        stdlib.info "$_name state: present, needs updated."
        keepalived.vrrp_instance.delete
        keepalived.vrrp_instance.create
        ;;
    esac
  fi
}

function keepalived.vrrp_instance.read {
  if [[ ! -f "$_file" ]]; then
    stdlib_current_state="absent"
    return
  fi

  # Check if the vrrp_instance exists
  stdlib_current_state=$(augeas.get --lens Keepalived --file "$_file" --path "/vrrp_instance[. = '${options[name]}']")
  if [[ "$stdlib_current_state" == "absent" ]]; then
    return
  fi

  # Check if the virtual_ipaddresses exist
  for v in "${virtual_ipaddress[@]}"; do
    _result=$(augeas.get --lens Keepalived --file "$_file" --path "/vrrp_instance[. = '${options[name]}']/virtual_ipaddress/ipaddr[. = '$v']")
    if [[ "$_result" == "absent" ]]; then
      options_to_update["virtual_ipaddress"]=1
      stdlib_current_state="update"
    fi
  done

  # Check if the unicast peer IPs exist
  for u in "${unicast_peer[@]}"; do
    _result=$(augeas.get --lens Keepalived --file "$_file" --path "/vrrp_instance[. = '${options[name]}']/unicast_peer/ipaddr[. = '$u']")
    if [[ "$_result" == "absent" ]]; then
      options_to_update["unicast_peer"]=1
      stdlib_current_state="update"
    fi
  done

  # Check authentication
  for a in "${auth_keys[@]}"; do
    if [[ -n "${options[$a]}" ]]; then
      _result=$(augeas.get --lens Keepalived --file "$_file" --path "/vrrp_instance[. = '${options[name]}']/authentication/$a[. = '${options[$a]}']")
      if [[ "$_result" == "absent" ]]; then
        options_to_update[$a]=1
        stdlib_current_state="update"
      fi
    fi
  done

  # Check if the other keys are set

  # Handle state in a special way since it conflicts with the "state" option
  _result=$(augeas.get --lens Keepalived --file "$_file" --path "/vrrp_instance[. = '${options[name]}']/state[. = '${options[vrrp_state]}']")
  if [[ "$_result" == "absent" ]]; then
    options_to_update["vrrp_state"]=1
    stdlib_current_state="update"
  fi

  # Other simple keys
  for o in "${simple_options[@]}"; do
    if [[ -n "${options[$o]}" ]]; then
      _result=$(augeas.get --lens Keepalived --file "$_file" --path "/vrrp_instance[. = '${options[name]}']/$o[. = '${options[$o]}']")
      if [[ "$_result" == "absent" ]]; then
        options_to_update[$o]=1
        stdlib_current_state="update"
      fi
    fi
  done

  # Boolean keys
  for b in "${boolean_keys[@]}"; do
    if [[ -n "${options[$b]}" ]]; then
      _result=$(augeas.get --lens Keepalived --file "$_file" --path "/vrrp_instance[. = '${options[name]}']/$b")
      if [[ "$_result" == "absent" ]]; then
        options_to_update[$b]=1
        stdlib_current_state="update"
      fi
    fi
  done

  if [[ "$stdlib_current_state" == "update" ]]; then
    return
  else
    stdlib_current_state="present"
  fi

}

function keepalived.vrrp_instance.create {
  local _result
  local -a _augeas_commands=()

  if [[ ! -d "$_dir" ]]; then
    stdlib.capture_error mkdir -p "$_dir"
  fi

  # Create the vrrp_instance
  if [[ "$stdlib_current_state" == "absent" ]]; then
    _augeas_commands+=("set /files/${_file}/vrrp_instance[0] '${options[name]}'")
  fi

  # Set virtual_ipaddress
  if [[ "${options_to_update[virtual_ipaddress]+isset}" || "$stdlib_current_state" == "absent" ]]; then
    for n in "${virtual_ipaddress[@]}"; do
      _augeas_commands+=("set /files/${_file}/vrrp_instance[. = '${options[name]}']/virtual_ipaddress/ipaddr[0] '$n'")
    done
  fi

  # Set unicast_peers
  if [[ "${options_to_update[unicast_peer]+isset}" || "$stdlib_current_state" == "absent" ]]; then
    for n in "${unicast_peer[@]}"; do
      _augeas_commands+=("set /files/${_file}/vrrp_instance[. = '${options[name]}']/unicast_peer/ipaddr[0] '$n'")
    done
  fi

  # Set authentication options
  if [[ "${options_to_update[auth_type]+isset}" || "$stdlib_current_state" == "absent" ]]; then
    if [[ -n "${options[auth_type]}" ]]; then
      _augeas_commands+=("set /files/${_file}/vrrp_instance[. = '${options[name]}']/authentication/auth_type '${options[auth_type]}'")
      _augeas_commands+=("set /files/${_file}/vrrp_instance[. = '${options[name]}']/authentication/auth_pass '${options[auth_pass]}'")
    fi
  fi

  # Handle state in a special way since it conflicts with the "state" option
  _augeas_commands+=("set /files/${_file}/vrrp_instance[. = '${options[name]}']/state '${options[vrrp_state]}'")

  # Set simple options
  for o in "${simple_options[@]}"; do
    if [[ "${options_to_update[$o]+isset}" || "$stdlib_current_state" == "absent" ]]; then
      if [[ -n "${options[$o]}" ]]; then
        _augeas_commands+=("set /files/${_file}/vrrp_instance[. = '${options[name]}']/$o '${options[$o]}'")
      fi
    fi
  done

  # Set boolean options
  for b in "${boolean_options[@]}"; do
    if [[ "${options_to_update[$b]+isset}" || "$stdlib_current_state" == "absent" ]]; then
      if [[ "${options[$b]}" != "false" ]]; then
        _augeas_commands+=("touch /files/${_file}/vrrp_instance[. = '${options[name]}']/$b")
      fi
    fi
  done

  _result=$(augeas.run --lens Keepalived --file "$_file" "${_augeas_commands[@]}")
  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function keepalived.vrrp_instance.delete {
  local _result
  local -a _augeas_commands=()

  # Delete virtual_ipaddress
  if [[ "${options_to_update[virtual_ipaddress]+isset}" ]]; then
    for n in "${virtual_ipaddress[@]}"; do
      _augeas_commands+=("rm /files/${_file}/vrrp_instance[. = '${options[name]}']/virtual_ipaddress")
    done
  fi

  # Delete unicast_peers
  if [[ "${options_to_update[unicast_peer]+isset}" ]]; then
    for n in "${unicast_peer[@]}"; do
      _augeas_commands+=("rm /files/${_file}/vrrp_instance[. = '${options[name]}']/unicast_peer")
    done
  fi

  # Delete authentication options
  if [[ "${options_to_update[auth_type]+isset}" ]]; then
    _augeas_commands+=("set /files/${_file}/vrrp_instance[. = '${options[name]}']/authentication")
  fi

  # Handle state in a special way since it conflicts with the "state" option
  _augeas_commands+=("rm /files/${_file}/vrrp_instance[. = '${options[name]}']/state '${options[vrrp_state]}'")

  # Delete simple options
  for o in "${simple_options[@]}"; do
    if [[ "${options_to_update[$o]+isset}" ]]; then
      _augeas_commands+=("rm /files/${_file}/vrrp_instance[. = '${options[name]}']/$o")
    fi
  done

  # Delete boolean options
  for b in "${boolean_options[@]}"; do
    if [[ "${options_to_update[$b]+isset}" ]]; then
      _augeas_commands+=("rm /files/${_file}/vrrp_instance[. = '${options[name]}']/$o")
    fi
  done

  _result=$(augeas.run --lens Keepalived --file "$_file" "${_augeas_commands[@]}")
  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error adding $_name with augeas: $_result"
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}
