# == Name
#
# consul.service
#
# === Description
#
# Manages a consul service.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the service. Required.
# * id: A unique ID for the service. Optional.
# * tag: Tags to describe the service. Optional. Multi-var.
# * address: The address of the service. Optional.
# * port: The port that the service runs on. Optional.
# * token: An ACL token. Optional.
# * check: The script or location for the check. Optional. Multi-var.
# * check_type: The type of check. Optional. Multi-var.
# * check_interval: The interval to run the script. Optional. Multi-var.
# * check_ttl: The TTL of the check. Optional. Multi-var.
# * file: The file to store the service in. Required. Defaults to /etc/consul/agent/conf.d/service-name.json
# * file_owner: The owner of the service file. Optional. Defaults to root.
# * file_group: The group of the service file. Optional. Defaults to root.
# * file_mode: The mode of the service file. Optional. Defaults to 0640
#
# === Example
#
# ```shell
# consul.service --name mysql \
#                --port 3306 \
#                --check_type "script" \
#                --check "/usr/local/bin/check_mysql.sh" \
#                --check_interval "60s"
# ```
#
function consul.service {
  # Declare the resource
  waffles_resource="consul.service"

  # Resource Options
  local -A options
  local -a tag
  local -a check
  local -a check_type
  local -a check_interval
  local -a check_ttl
  waffles.options.create_option    state   "present"
  waffles.options.create_option    name    "__required__"
  waffles.options.create_option    id
  waffles.options.create_option    address
  waffles.options.create_option    port
  waffles.options.create_option    token
  waffles.options.create_mv_option tag
  waffles.options.create_mv_option check
  waffles.options.create_mv_option check_type
  waffles.options.create_mv_option check_interval
  waffles.options.create_mv_option check_ttl
  waffles.options.create_option    file
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
  local _simple_options=(name id address port token)
  local _check_options=(check check_type check_interval check_ttl)

  # Internal Resource Configuration
  if ! waffles.command_exists jsed ; then
    log.error "Cannot find jsed"
    return 1
  fi

  if [[ -z ${options[file]} ]]; then
    _file="/etc/consul/agent/conf.d/service-${options[name]}.json"
  else
    _file="${options[file]}"
  fi

  # Process the resource
  waffles.resource.process $waffles_resource "$_name"
}

function consul.service.read {
  if [[ ! -f $_file ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  _service=$(consul.service.build_service)
  _existing_md5=$(md5sum "$_file" | cut -d' ' -f1)
  _new_md5=$(echo $_service | md5sum | cut -d' ' -f1)

  if [[ "$_existing_md5" != "$_new_md5" ]]; then
    waffles_resource_current_state="update"
    return
  fi

  waffles_resource_current_state="present"
}

function consul.service.create {
  if [[ ! -d $_dir ]]; then
    exec.capture_error mkdir -p "$_dir"
  fi

  _service=$(consul.service.build_service)
  echo "$_service" > "$_file"
  os.file --name "$_file" --content "$_service" --owner "${options[file_owner]}" --group "${options[file_group]}" --mode "${options[file_mode]}"
}

function consul.service.update {
  consul.service.delete
  consul.service.create
}

function consul.service.delete {
  exec.capture_error rm "$_file"
}

function consul.service.build_service {
  _service="{}"

  # Build simple options
  for _o in "${_simple_options[@]}"; do
    if [[ -n ${options[$_o]} ]]; then
      _service=$(echo "$_service" | jsed add object --path service --key "$_o" --value "${options[$_o]}")
    fi
  done

  # Build tags
  for _tag in "${tag[@]}"; do
    _tags="$_tags --value $_tag"
  done

  if [[ -n $_tags ]]; then
    _service=$(echo "$_service" | jsed add array --path service.tags $_tags)
  fi

  # Build check(s)
  _service=$(echo "$_service" | jsed add object --path service --key checks --value [])
  _i=0
  for _o in "${check[@]}"; do
    _check="--key ${check_type[$_i]} --value ${check[$_i]}"

    if  [[ -n ${check_interval[$_i]} ]]; then
      _check="${_check} --key interval --value ${check_interval[$_i]}"
    fi

    if [[ -n ${check_ttl[$_i]} ]]; then
      _check="${_check} --key ttl --value ${check_ttl[$_i]}"
    fi

    _service=$(echo "$_service" | jsed add object --path service.checks $_check)

    _i=$(( _i+1 ))
  done

  echo "$_service"
}
