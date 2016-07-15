# == Name
#
# sudoers.cmd
#
# === Description
#
# Provides an easy way to give a user sudo access to a single command
# defined in a sudoers.d file.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * user: The user of the sudo privilege. Required.
# * command: The command of the sudo privilege. Required.
# * password: Whether to prompt for a password. Required. Default: false.
#
# === Example
#
# ```bash
# sudoers.cmd --user consul --command /usr/local/bin/consul_build_hosts_file.sh
# ```
#
sudoers.cmd() {
  # Declare the resource
  waffles_resource="sudoers.cmd"

  # Check if all dependencies are installed
  local _wrd=("getent")
  if ! waffles.resource.check_dependencies "${_wrd[@]}" ; then
    return 1
  fi

  # Resource Options
  local -A options
  waffles.options.create_option state    "present"
  waffles.options.create_option user     "__required__"
  waffles.options.create_option command  "__required__"
  waffles.options.create_option password "false"
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi


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
  waffles.resource.process $waffles_resource "$_name"
}

sudoers.cmd.read() {
  if [[ ! -f "$_file" ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  exec.mute diff "$_file" \<\(echo "$_line"\)
  if [[ $? == 1 ]]; then
    waffles_resource_current_state="update"
    return
  fi

  waffles_resource_current_state="present"
}

sudoers.cmd.create() {
  os.file --name "$_file" --owner root --group root --mode 440 --content "$_line"
}

sudoers.cmd.update() {
  sudoers.cmd.delete
  sudoers.cmd.create
}

sudoers.cmd.delete() {
  exec.capture_error rm "$_file"
}
