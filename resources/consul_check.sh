# == Name
#
# consul.check
#
# === Description
#
# Manages a consul.check.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the check Required.
# * id: A unique ID for the check. Optional.
# * service_id: A service to tie the check to. Optional.
# * notes: Notes about the check. Optional.
# * token: An ACL token. Optional.
# * check: The script or http location for the check. Optional.
# * type: The type of check: script, http, or ttl. Required.
# * interval: The interval to run the script. Optional.
# * ttl: The TTL of the check. Optional.
# * file: The file to store the check in. Required. Defaults to /etc/consul/agent/conf.d/check-name.json
# * file_owner: The owner of the service file. Optional. Defaults to root.
# * file_group: The group of the service file. Optional. Defaults to root.
# * file_mode: The mode of the service file. Optional. Defaults to 0640
#
# === Example
#
# ```shell
# consul.check --name mysql \
#              --check "/usr/local/bin/check_mysql.sh" \
#              --type "script" \
#              --interval "60s"
# ```
#
function consul.check {
  # Declare the resource
  waffles_resource="consul.check"

  # Resource Options
  local -A options
  waffles.options.create_option state      "present"
  waffles.options.create_option name       "__required__"
  waffles.options.create_option type       "__required__"
  waffles.options.create_option id
  waffles.options.create_option service_id
  waffles.options.create_option notes
  waffles.options.create_option token
  waffles.options.create_option check
  waffles.options.create_option interval
  waffles.options.create_option ttl
  waffles.options.create_option file
  waffles.options.create_option    file_owner "root"
  waffles.options.create_option    file_group "root"
  waffles.options.create_option    file_mode  "640"
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi


  # Local Variables
  local _file
  local _name="${options[name]}"
  local _dir=$(dirname "${options[file]}")
  local _simple_options=(name id notes token interval ttl)

  # Internal Resource configuration
  if ! waffles.command_exists jsed ; then
    log.error "Cannot find jsed"
    return 1
  fi

  if [[ -z ${options[file]} ]]; then
    _file="/etc/consul/agent/conf.d/check-${options[name]}.json"
  else
    _file="${options[file]}"
  fi

  # Process the resource
  waffles.resource.process $waffles_resource "$_name"
}

function consul.check.read {
  if [[ ! -f $_file ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  _check=$(consul.check.build_check)
  _existing_md5=$(md5sum "$_file" | cut -d' ' -f1)
  _new_md5=$(echo $_service | md5sum | cut -d' ' -f1)

  if [[ "$_existing_md5" != "$_new_md5" ]]; then
    waffles_resource_current_state="update"
    return
  fi

  waffles_resource_current_state="present"
}

function consul.check.create {
  if [[ ! -d $_dir ]]; then
    exec.capture_error mkdir -p "$_dir"
  fi

  _check=$(consul.check.build_check)
  os.file --name "$_file" --content "$_service" --owner "${options[file_owner]}" --group "${options[file_group]}" --mode "${options[file_mode]}"
}

function consul.check.update {
  consul.check.delete
  consul.check.create
}

function consul.check.delete {
  os.file -state absent --name "$_file"
}

function consul.check.build_check {
  _check="{}"

  # Build simple options
  for _o in "${_simple_options[@]}"; do
    if [[ -n ${options[$_o]} ]]; then
      _check=$(echo "$_check" | jsed add object --path "check.${_o}" --value "${options[$_]}")
    fi
  done

  if [[ ${options[type]} != "ttl" ]]; then
    _check=$(echo  "$_check" | jsed add object --path check --key "${options[type]}" --value "${options[check]}")
  fi

  echo "$_check"
}
