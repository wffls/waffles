# == Name
#
# consul.watch
#
# === Description
#
# Manages a consul.watch.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the watch. Required.
# * type: The type of watch: key, keyprefix, services, nodes, service, checks, event. Required.
# * key: A key to monitor when using type "key". Optional.
# * prefix: A prefix to monitor when using type "keyprefix". Optional.
# * service: A service to monitor when using type "service" or "checks". Optional.
# * tag: A service tag to monitor when using type "service". Optional.
# * passingonly: Only return instances passing all health checks when using type "service". Optional.
# * check_state: A state to filter on when using type "checks". Optional.
# * event_name: An event to filter on when using type "event. Optional.
# * datacenter: Can be provided to override the agent's default datacenter. Optional.
# * token: Can be provided to override the agent's default ACL token. Optional.
# * handler: The handler to invoke when the data view updates. Required.
# * file: The file to store the watch in. Required. Defaults to /etc/consul/agent/conf.d/watch-name.json
# * file_owner: The owner of the service file. Optional. Defaults to root.
# * file_group: The group of the service file. Optional. Defaults to root.
# * file_mode: The mode of the service file. Optional. Defaults to 0640
#
# === Example
#
# ```shell
# consul.watch --name nodes \
#              --type nodes \
#              --handler "/usr/local/bin/build_hosts_file.sh"
# ```
#
consul.watch() {
  # Declare the resource
  waffles_resource="consul.watch"

  # Resource Options
  local -A options
  waffles.options.create_option state      "present"
  waffles.options.create_option name       "__required__"
  waffles.options.create_option type       "__required__"
  waffles.options.create_option handler    "__required__"
  waffles.options.create_option token
  waffles.options.create_option datacenter
  waffles.options.create_option key
  waffles.options.create_option prefix
  waffles.options.create_option service
  waffles.options.create_option tag
  waffles.options.create_option passingonly
  waffles.options.create_option check_state
  waffles.options.create_option event_name
  waffles.options.create_option file
  waffles.options.create_option file_owner "root"
  waffles.options.create_option file_group "root"
  waffles.options.create_option file_mode  "640"
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi


  # Local Variables
  local _file
  local _name="${options[name]}"
  local _dir=$(dirname "${options[file]}")
  local _simple_options=(type handler token datacenter key prefix service tag passingonly)

  # Internal Resource configuration
  if ! waffles.command_exists jsed ; then
    log.error "Cannot find jsed"
    return 1
  fi

  if ! waffles.command_exists consul ; then
    log.error "Cannot find consul"
    return 1
  fi

  if [[ -z ${options[file]} ]]; then
    _file="/etc/consul/agent/conf.d/watch-${options[name]}.json"
  else
    _file="${options[file]}"
  fi

  # Process the resource
  waffles.resource.process $waffles_resource "$_name"
}

consul.watch.read() {
  if [[ ! -f $_file ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  _watch=$(consul.watch.build_watch)
  _existing_md5=$(md5sum "$_file" | cut -d' ' -f1)
  _new_md5=$(echo $_watch | md5sum | cut -d' ' -f1)

  if [[ "$_existing_md5" != "$_new_md5" ]]; then
    waffles_resource_current_state="update"
    return
  fi

  waffles_resource_current_state="present"
}

consul.watch.create() {
  if [[ ! -d $_dir ]]; then
    exec.capture_error mkdir -p "$_dir"
  fi

  _watch=$(consul.watch.build_watch)
  os.file --name "$_file" --content "$_watch" --owner "${options[file_owner]}" --group "${options[file_group]}" --mode "${options[file_mode]}"
}

consul.watch.update() {
  consul.watch.delete
  consul.watch.create
}

consul.watch.delete() {
  os.file --state absent --name "$_file"
}

consul.watch.build_watch() {
  _watch='{"watches":[]}'
  _options=""

  # Build simple options
  for _o in "${_simple_options[@]}"; do
    if [[ -n ${options[$_o]} ]]; then
      _watch_options="${_options} --key '$_o' --value '${options[$_o]}'"
    fi
  done

  _watch=$(echo "$_watch" | jsed add object --path watches "$_watch_options")

  # check_state conflicts with "state" option, so we need to make a special check here
  if [[ -n ${options[check_state]} ]]; then
    _watch=$(echo "$_watch" | jsed add object --path watches.0.state --key "${options[check_state]}")
  fi

  # event_name conflicts with "name" option, so we need to make a special check here
  if [[ -n ${options[event_name]} ]]; then
    _watch=$(echo "$_watch" | jsed add object --path watches.0.name --key "${options[event_name]}")
  fi

  echo "$_watch"
}
