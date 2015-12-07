# == Name
#
# stdlib.sudo_cmd
#
# === Description
#
# Provides an easy way to give a user sudo access to a single command.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * user: The user of the sudo privilege. Required. namevar.
# * command: The command of the sudo privilege. Required. namevar.
# * password: Whether to prompt for a password. Required. Default: false.
#
# === Example
#
# ```shell
# stdlib.sudo_cmd --user consul --command /usr/local/bin/consul_build_hosts_file.sh
# ```
#
function stdlib.sudo_cmd {
  stdlib.subtitle "stdlib.sudo_cmd"

  # Resource Options
  local -A options
  stdlib.options.create_option state    "present"
  stdlib.options.create_option user     "__required__"
  stdlib.options.create_option command  "__required__"
  stdlib.options.create_option password "false"
  stdlib.options.parse_options "$@"

  # Local Variables
  local _user_info=$(getent passwd "${options[user]}")
  local _cmd_name=$(basename "${options[command]}")
  _cmd_name="${_cmd_name%%.*}"
  _cmd_name="${_cmd_name// /_}"
  local _name="${options[user]}-${_cmd_name}"
  local _file="/etc/sudoers.d/${_name}"

  # Internal Resource Configuration
  if [[ -n $_user_info ]]; then
    stdlib.split "$_user_info" ':'
    _uid="${__split[2]}"
  else
    stdlib.error "User ${options[user]} does not exist."
    return 1
  fi

  if [[ ${options[password]} == "false" ]]; then
    local _line="${options[user]} ALL = NOPASSWD: ${options[command]}"
  else
    local _line="${options[user]} ALL = PASSWD: ${options[command]}"
  fi

  # Process the resource
  stdlib.resource.process "stdlib.sudo_cmd" "$_name"
}

function stdlib.sudo_cmd.read {
  if [[ ! -f "$_file" ]]; then
    stdlib_current_state="absent"
    return
  fi

  stdlib.debug_mute diff "$_file" \<\(echo "$_line"\)
  if [[ $? == 1 ]]; then
    stdlib_current_state="update"
    return
  fi

  stdlib_current_state="present"
}

function stdlib.sudo_cmd.create {
  stdlib.file --name "$_file" --owner root --group root --mode 440 --content "$_line"
}

function stdlib.sudo_cmd.update {
  stdlib.sudo_cmd.delete
  stdlib.sudo_cmd.create
}

function stdlib.sudo_cmd.delete {
  stdlib.capture_error rm "$_file"
}
