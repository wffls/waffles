# == Name
#
# keepalived.vrrp_script
#
# === Description
#
# Manages vrrp_script section in keepalived.conf
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the VRRP instance. Required. namevar.
# * script: The script to define. Required.
# * interval: The interval to run the script. Optional.
# * weight: The points for priority. Optional.
# * fall: Number of failures for KO. Optional.
# * raise: Number of successes for OK. Optional.
# * file: The file to store the settings in. Required. Defaults to /etc/keepalived/keepalived.conf.
#
# === Example
#
# ```shell
# keepalived.vrrp_script --name check_apache2 \
#                        --script "killall -0 apache2"
# ```
#
function keepalived.vrrp_script {
  waffles.subtitle "keepalived.vrrp_script"

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
  local -a group
  waffles.options.create_option state    "present"
  waffles.options.create_option name     "__required__"
  waffles.options.create_option script   "__required__"
  waffles.options.create_option file     "/etc/keepalived/keepalived.conf"
  waffles.options.create_option interval
  waffles.options.create_option weight
  waffles.options.create_option fall
  waffles.options.create_option raise
  waffles.options.parse_options "$@"

  # Local Variables
  local _name="${options[name]}"
  local _dir=$(dirname "${options[file]}")
  local _file="${options[file]}"
  local -a simple_options=("script" "interval" "weight" "raise" "fall")
  local -A options_to_update

  # Process the resource
  waffles.resource.process "keepalived.vrrp_script" "$_name"
}

function keepalived.vrrp_script.read {
  if [[ ! -f $_file ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  # Check if the vrrp_script exists
  waffles_resource_current_state=$(augeas.get --lens Keepalived --file "$_file" --path "/vrrp_script[. = '${options[name]}']")
  if [[ $waffles_resource_current_state == "absent" ]]; then
    return
  fi

  # simple keys
  for o in "${simple_options[@]}"; do
    if [[ -n ${options[$o]} ]]; then
      _result=$(augeas.get --lens Keepalived --file "$_file" --path "/vrrp_script[. = '${options[name]}']/$o[. = '${options[$o]}']")
      if [[ $_result == "absent" ]]; then
        options_to_update[$o]=1
        waffles_resource_current_state="update"
      fi
    fi
  done

  # Set simple options
  for o in "${simple_options[@]}"; do
    if [[ ${options_to_update[$o]+isset} || $waffles_resource_current_state == "absent" ]]; then
      if [[ -n ${options[$o]} ]]; then
        _augeas_commands+=("set /files/${_file}/vrrp_script[. = '${options[name]}']/$o '${options[$o]}'")
      fi
    fi
  done

  if [[ $waffles_resource_current_state == "update" ]]; then
    return
  else
    waffles_resource_current_state="present"
  fi
}

function keepalived.vrrp_script.create {
  local _result
  local -a _augeas_commands=()

  if [[ ! -d $_dir ]]; then
    exec.capture_error mkdir -p "$_dir"
  fi

  # Create the vrrp_script
  if [[ $waffles_resource_current_state == "absent" ]]; then
    _augeas_commands+=("set /files/${_file}/vrrp_script[0] '${options[name]}'")
  fi

  # Create simple options
  for o in "${simple_options[@]}"; do
    if [[ ${options_to_update[$o]+isset} || $waffles_resource_current_state == "absent" ]]; then
      if [[ -n ${options[$o]} ]]; then
        _augeas_commands+=("set /files/${_file}/vrrp_script[. = '${options[name]}']/$o '${options[$o]}'")
      fi
    fi
  done

  _result=$(augeas.run --lens Keepalived --file "$_file" "${_augeas_commands[@]}")
  if [[ $_result =~ ^error ]]; then
    log.error "Error adding $_name with augeas: $_result"
  fi
}

function keepalived.vrrp_script.update {
  keepalived.vrrp_script.delete
  keepalived.vrrp_script.create
}

function keepalived.vrrp_script.delete {
  local _result
  local -a _augeas_commands=()

  _result=$(augeas.run --lens Keepalived --file "$_file" "${_augeas_commands[@]}")
  if [[ $_result =~ ^error ]]; then
    log.error "Error adding $_name with augeas: $_result"
  fi
}
