# == Name
#
# sudo.cmd
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
# sudo.cmd --user consul --command /usr/local/bin/consul_build_hosts_file.sh
# ```
#
function sudo.cmd {
  waffles.subtitle "sudo.cmd"

  # Resource Options
  local -A options
  waffles.options.create_option state    "present"
  waffles.options.create_option user     "__required__"
  waffles.options.create_option command  "__required__"
  waffles.options.create_option password "false"
  waffles.options.parse_options "$@"

  # Local Variables
  local _user_info=$(getent passwd "${options[user]}")
  local _cmd_name=$(basename "${options[command]}")
  _cmd_name="${_cmd_name%%.*}"
  _cmd_name="${_cmd_name// /_}"
  local _name="${options[user]}-${_cmd_name}"
  local _file="/etc/sudoers.d/${_name}"

  # Internal Resource Configuration
  if [[ -n $_user_info ]]; then
    string.split "$_user_info" ':'
    _uid="${__split[2]}"
  else
    log.error "User ${options[user]} does not exist."
    return 1
  fi

  if [[ ${options[password]} == "false" ]]; then
    local _line="${options[user]} ALL = NOPASSWD: ${options[command]}"
  else
    local _line="${options[user]} ALL = PASSWD: ${options[command]}"
  fi

  # Process the resource
  waffles.resource.process "sudo.cmd" "$_name"
}

function sudo.cmd.read {
  if [[ ! -f "$_file" ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  exec.debug_mute diff "$_file" \<\(echo "$_line"\)
  if [[ $? == 1 ]]; then
    waffles_resource_current_state="update"
    return
  fi

  waffles_resource_current_state="present"
}

function sudo.cmd.create {
  os.file --name "$_file" --owner root --group root --mode 440 --content "$_line"
}

function sudo.cmd.update {
  sudo.cmd.delete
  sudo.cmd.create
}

function sudo.cmd.delete {
  exec.capture_error rm "$_file"
}
