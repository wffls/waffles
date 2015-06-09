# == Name
#
# augeas.cron
#
# === Description
#
# Manages a cron entry in /etc/cron.d/
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: An arbitrary name for the cron Required. namevar.
# * user: The user to run the cron under. Default: root.
# * minute: The minute to run the cron. Default: *.
# * hour: The hour to run the cron. Default: *.
# * dom: The day of month to run the cron. Default: *.
# * month: The month to run the cron. Default *.
# * dow: The day of the week to run the cron. Default *.
# * cmd: The command to run. Required.
#
# === Example
#
# augeas.cron --name metrics --minute "*/5" --cmd /usr/local/bin/collect_metrics.sh
#
function augeas.cron {
  stdlib.subtitle "augeas.cron"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ $WAFFLES_EXIT_ON_ERROR == true ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  stdlib.options.set_option state  "present"
  stdlib.options.set_option name   "__required__"
  stdlib.options.set_option user   "root"
  stdlib.options.set_option minute "*"
  stdlib.options.set_option hour   "*"
  stdlib.options.set_option dom    "*"
  stdlib.options.set_option month  "*"
  stdlib.options.set_option dow    "*"
  stdlib.options.set_option cmd    "__required__"
  stdlib.options.parse_options "$@"

  stdlib.catalog.add "augeas.cron/${options[name]}"

  local _file="/etc/cron.d/${options[name]}"

  augeas.cron.read
  if [[ ${options[state]} == absent ]]; then
    if [[ $stdlib_current_state != absent ]]; then
      stdlib.info "$_name state: $stdlib_current_state, should be absent."
      augeas.cron.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "${options[name]} state: absent, should be present."
        augeas.cron.create
        ;;
      present)
        stdlib.debug "${options[name]} state: present."
        ;;
      update)
        stdlib.info "${options[name]} state: present, needs updated."
        augeas.cron.delete
        augeas.cron.create
        ;;
    esac
  fi
}

function augeas.cron.read {
  local _result

  # Check if the cron command exists
  stdlib_current_state=$(augeas.get --lens Cron --file "$_file" --path "/entry[. = '${options[cmd]}']")
  if [[ $stdlib_current_state == absent ]]; then
    return
  fi

  # If so, check if the other attributes match
  _result=$(augeas.get --lens Cron --file "$_file" --path "/entry[. = '${options[cmd]}']/time/minute[. = '${options[minute]}']")
  if [[ $_result == absent ]]; then
    stdlib_current_state="update"
    return
  fi

  _result=$(augeas.get --lens Cron --file "$_file" --path "/entry[. = '${options[cmd]}']/time/hour[. = '${options[hour]}']")
  if [[ $_result == absent ]]; then
    stdlib_current_state="update"
    return
  fi

  _result=$(augeas.get --lens Cron --file "$_file" --path "/entry[. = '${options[cmd]}']/time/dayofmonth[. = '${options[dom]}']")
  if [[ $_result == absent ]]; then
    stdlib_current_state="update"
    return
  fi

  _result=$(augeas.get --lens Cron --file "$_file" --path "/entry[. = '${options[cmd]}']/time/month[. = '${options[month]}']")
  if [[ $_result == absent ]]; then
    stdlib_current_state="update"
    return
  fi

  _result=$(augeas.get --lens Cron --file "$_file" --path "/entry[. = '${options[cmd]}']/time/dayofweek[. = '${options[dow]}']")
  if [[ $_result == absent ]]; then
    stdlib_current_state="update"
    return
  fi

  _result=$(augeas.get --lens Cron --file "$_file" --path "/entry[. = '${options[cmd]}']/user[. = '${options[user]}']")
  if [[ $_result == absent ]]; then
    stdlib_current_state="update"
    return
  fi
}

function augeas.cron.create {
  local -a _augeas_commands=()
  _augeas_commands+=("set /files${_file}/entry[last()+1] '${options[cmd]}'")
  _augeas_commands+=("set /files${_file}/entry[. = '${options[cmd]}']/time/minute '${options[minute]}'")
  _augeas_commands+=("set /files${_file}/entry[. = '${options[cmd]}']/time/hour '${options[hour]}'")
  _augeas_commands+=("set /files${_file}/entry[. = '${options[cmd]}']/time/dayofmonth '${options[dom]}'")
  _augeas_commands+=("set /files${_file}/entry[. = '${options[cmd]}']/time/month '${options[month]}'")
  _augeas_commands+=("set /files${_file}/entry[. = '${options[cmd]}']/time/dayofweek '${options[dow]}'")
  _augeas_commands+=("set /files${_file}/entry[. = '${options[cmd]}']/user '${options[user]}'")

  local _result=$(augeas.run --lens Cron --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ ^error ]]; then
    stdlib.error "Error adding cron ${options[name]} with augeas: $_result"
    return
  fi
}

function augeas.cron.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files${_file}/entry[. = '${options[cmd]}']")
  local _result=$(augeas.run --lens Cron --file "$_file" "${_augeas_commands[@]}")

  if [[ $_result =~ "^error" ]]; then
    stdlib.error "Error deleting cron ${options[name]} with augeas: $_result"
    return
  fi
}
