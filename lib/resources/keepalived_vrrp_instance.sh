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
  waffles.subtitle "keepalived.vrrp_instance"

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
  local -a virtual_ipaddress
  local -a unicast_peer
  waffles.options.create_option    state             "present"
  waffles.options.create_option    name              "__required__"
  waffles.options.create_option    vrrp_state        "__required__"
  waffles.options.create_option    interface         "__required__"
  waffles.options.create_option    virtual_router_id "__required__"
  waffles.options.create_option    priority          "__required__"
  waffles.options.create_option    file              "/etc/keepalived/keepalived.conf"
  waffles.options.create_option    smtp_alert        "false"
  waffles.options.create_option    native_ipv6       "false"
  waffles.options.create_option    debug             "false"
  waffles.options.create_option    advert_int
  waffles.options.create_option    auth_type
  waffles.options.create_option    auth_pass
  waffles.options.create_option    unicast_src_ip
  waffles.options.create_option    notify_master
  waffles.options.create_option    notify_backup
  waffles.options.create_option    notify_fault
  waffles.options.create_option    notify
  waffles.options.create_mv_option virtual_ipaddress
  waffles.options.create_mv_option unicast_peer
  waffles.options.parse_options    "$@"

  # Local Variables
  local _name="${options[name]}"
  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"
  local -A options_to_update
  local -a simple_options=("interface" "virtual_router_id" "priority" "advert_int" "unicast_src_ip" "notify_master" "notify_backup" "notify_fault" "notify")
  local -a auth_keys=("auth_type" "auth_pass")
  local -a boolean_options=("smtp_alert" "native_ipv6" "debug")

  # Internal Resource Configuration
  # If auth_type is set, make sure auth_pass is set
  if [[ -n ${options[auth_type]} && -z ${options[auth_pass]} ]]; then
    log.error "Both auth_type and auth_pass must be set."
    return
  fi

  # Process the resource
  waffles.resource.process "keepalived.vrrp_instance" "$_name"
}

function keepalived.vrrp_instance.read {
  if [[ ! -f $_file ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  # Check if the vrrp_instance exists
  waffles_resource_current_state=$(augeas.get --lens Keepalived --file "$_file" --path "/vrrp_instance[. = '${options[name]}']")
  if [[ $waffles_resource_current_state == "absent" ]]; then
    return
  fi

  # Check if the virtual_ipaddresses exist
  for v in "${virtual_ipaddress[@]}"; do
    _result=$(augeas.get --lens Keepalived --file "$_file" --path "/vrrp_instance[. = '${options[name]}']/virtual_ipaddress/ipaddr[. = '$v']")
    if [[ $_result == "absent" ]]; then
      options_to_update["virtual_ipaddress"]=1
      waffles_resource_current_state="update"
    fi
  done

  # Check if the unicast peer IPs exist
  for u in "${unicast_peer[@]}"; do
    _result=$(augeas.get --lens Keepalived --file "$_file" --path "/vrrp_instance[. = '${options[name]}']/unicast_peer/ipaddr[. = '$u']")
    if [[ $_result == "absent" ]]; then
      options_to_update["unicast_peer"]=1
      waffles_resource_current_state="update"
    fi
  done

  # Check authentication
  for a in "${auth_keys[@]}"; do
    if [[ -n ${options[$a]} ]]; then
      _result=$(augeas.get --lens Keepalived --file "$_file" --path "/vrrp_instance[. = '${options[name]}']/authentication/$a[. = '${options[$a]}']")
      if [[ $_result == "absent" ]]; then
        options_to_update[$a]=1
        waffles_resource_current_state="update"
      fi
    fi
  done

  # Check if the other keys are set

  # Handle state in a special way since it conflicts with the "state" option
  _result=$(augeas.get --lens Keepalived --file "$_file" --path "/vrrp_instance[. = '${options[name]}']/state[. = '${options[vrrp_state]}']")
  if [[ $_result == "absent" ]]; then
    options_to_update["vrrp_state"]=1
    waffles_resource_current_state="update"
  fi

  # Other simple keys
  for o in "${simple_options[@]}"; do
    if [[ -n ${options[$o]} ]]; then
      _result=$(augeas.get --lens Keepalived --file "$_file" --path "/vrrp_instance[. = '${options[name]}']/$o[. = '${options[$o]}']")
      if [[ $_result == "absent" ]]; then
        options_to_update[$o]=1
        waffles_resource_current_state="update"
      fi
    fi
  done

  # Boolean keys
  for b in "${boolean_keys[@]}"; do
    if [[ -n ${options[$b]} ]]; then
      _result=$(augeas.get --lens Keepalived --file "$_file" --path "/vrrp_instance[. = '${options[name]}']/$b")
      if [[ $_result == "absent" ]]; then
        options_to_update[$b]=1
        waffles_resource_current_state="update"
      fi
    fi
  done

  if [[ $waffles_resource_current_state == "update" ]]; then
    return
  else
    waffles_resource_current_state="present"
  fi

}

function keepalived.vrrp_instance.create {
  local _result
  local -a _augeas_commands=()

  if [[ ! -d $_dir ]]; then
    exec.capture_error mkdir -p "$_dir"
  fi

  # Create the vrrp_instance
  if [[ $waffles_resource_current_state == "absent" ]]; then
    _augeas_commands+=("set /files/${_file}/vrrp_instance[0] '${options[name]}'")
  fi

  # Set virtual_ipaddress
  if [[ ${options_to_update[virtual_ipaddress]+isset} || $waffles_resource_current_state == "absent" ]]; then
    for n in "${virtual_ipaddress[@]}"; do
      _augeas_commands+=("set /files/${_file}/vrrp_instance[. = '${options[name]}']/virtual_ipaddress/ipaddr[0] '$n'")
    done
  fi

  # Set unicast_peers
  if [[ ${options_to_update[unicast_peer]+isset} || $waffles_resource_current_state == "absent" ]]; then
    for n in "${unicast_peer[@]}"; do
      _augeas_commands+=("set /files/${_file}/vrrp_instance[. = '${options[name]}']/unicast_peer/ipaddr[0] '$n'")
    done
  fi

  # Set authentication options
  if [[ ${options_to_update[auth_type]+isset} || $waffles_resource_current_state == "absent" ]]; then
    if [[ -n ${options[auth_type]} ]]; then
      _augeas_commands+=("set /files/${_file}/vrrp_instance[. = '${options[name]}']/authentication/auth_type '${options[auth_type]}'")
      _augeas_commands+=("set /files/${_file}/vrrp_instance[. = '${options[name]}']/authentication/auth_pass '${options[auth_pass]}'")
    fi
  fi

  # Handle state in a special way since it conflicts with the "state" option
  _augeas_commands+=("set /files/${_file}/vrrp_instance[. = '${options[name]}']/state '${options[vrrp_state]}'")

  # Set simple options
  for o in "${simple_options[@]}"; do
    if [[ ${options_to_update[$o]+isset} || $waffles_resource_current_state == "absent" ]]; then
      if [[ -n ${options[$o]} ]]; then
        _augeas_commands+=("set /files/${_file}/vrrp_instance[. = '${options[name]}']/$o '${options[$o]}'")
      fi
    fi
  done

  # Set boolean options
  for b in "${boolean_options[@]}"; do
    if [[ ${options_to_update[$b]+isset} || $waffles_resource_current_state == "absent" ]]; then
      if [[ ${options[$b]} != "false" ]]; then
        _augeas_commands+=("touch /files/${_file}/vrrp_instance[. = '${options[name]}']/$b")
      fi
    fi
  done

  _result=$(augeas.run --lens Keepalived --file "$_file" "${_augeas_commands[@]}")
  if [[ $_result =~ ^error ]]; then
    log.error "Error adding $_name with augeas: $_result"
  fi
}

function keepalived.vrrp_instance.update {
  keepalived.vrrp_instance.delete
  keepalived.vrrp_instance.create
}

function keepalived.vrrp_instance.delete {
  local _result
  local -a _augeas_commands=()

  # Delete virtual_ipaddress
  if [[ ${options_to_update[virtual_ipaddress]+isset} ]]; then
    for n in "${virtual_ipaddress[@]}"; do
      _augeas_commands+=("rm /files/${_file}/vrrp_instance[. = '${options[name]}']/virtual_ipaddress")
    done
  fi

  # Delete unicast_peers
  if [[ ${options_to_update[unicast_peer]+isset} ]]; then
    for n in "${unicast_peer[@]}"; do
      _augeas_commands+=("rm /files/${_file}/vrrp_instance[. = '${options[name]}']/unicast_peer")
    done
  fi

  # Delete authentication options
  if [[ ${options_to_update[auth_type]+isset} ]]; then
    _augeas_commands+=("set /files/${_file}/vrrp_instance[. = '${options[name]}']/authentication")
  fi

  # Handle state in a special way since it conflicts with the "state" option
  _augeas_commands+=("rm /files/${_file}/vrrp_instance[. = '${options[name]}']/state '${options[vrrp_state]}'")

  # Delete simple options
  for o in "${simple_options[@]}"; do
    if [[ ${options_to_update[$o]+isset} ]]; then
      _augeas_commands+=("rm /files/${_file}/vrrp_instance[. = '${options[name]}']/$o")
    fi
  done

  # Delete boolean options
  for b in "${boolean_options[@]}"; do
    if [[ ${options_to_update[$b]+isset} ]]; then
      _augeas_commands+=("rm /files/${_file}/vrrp_instance[. = '${options[name]}']/$o")
    fi
  done

  _result=$(augeas.run --lens Keepalived --file "$_file" "${_augeas_commands[@]}")
  if [[ $_result =~ ^error ]]; then
    log.error "Error adding $_name with augeas: $_result"
  fi
}
