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
# * name: The name of the watch. Required. namevar.
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
function consul.watch {
  stdlib.subtitle "consul.watch"

  if ! stdlib.command_exists jsed ; then
    stdlib.error "Cannot find jsed"
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  if ! stdlib.command_exists consul ; then
    stdlib.error "Cannot find consul"
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  stdlib.options.create_option state      "present"
  stdlib.options.create_option name       "__required__"
  stdlib.options.create_option type       "__required__"
  stdlib.options.create_option handler    "__required__"
  stdlib.options.create_option token
  stdlib.options.create_option datacenter
  stdlib.options.create_option key
  stdlib.options.create_option prefix
  stdlib.options.create_option service
  stdlib.options.create_option tag
  stdlib.options.create_option passingonly
  stdlib.options.create_option check_state
  stdlib.options.create_option event_name
  stdlib.options.create_option file
  stdlib.options.create_option file_owner "root"
  stdlib.options.create_option file_group "root"
  stdlib.options.create_option file_mode  "640"
  stdlib.options.parse_options "$@"

  # Local Variables
  local _file
  local _name="${options[name]}"
  local _dir=$(dirname "${options[file]}")
  local _simple_options=(type handler token datacenter key prefix service tag passingonly)

  # Internal Resource configuration
  if [[ -z ${options[file]} ]]; then
    _file="/etc/consul/agent/conf.d/watch-${options[name]}.json"
  else
    _file="${options[file]}"
  fi

  # Process the resource
  stdlib.resource.process "consul.watch" "$_name"
}

function consul.watch.read {
  if [[ ! -f $_file ]]; then
    stdlib_current_state="absent"
    return
  fi

  _watch=$(consul.watch.build_watch)
  _existing_md5=$(md5sum "$_file" | cut -d' ' -f1)
  _new_md5=$(echo $_watch | md5sum | cut -d' ' -f1)

  if [[ "$_existing_md5" != "$_new_md5" ]]; then
    stdlib_current_state="update"
    return
  fi

  stdlib_current_state="present"
}

function consul.watch.create {
  if [[ ! -d $_dir ]]; then
    stdlib.capture_error mkdir -p "$_dir"
  fi

  _watch=$(consul.watch.build_watch)
  stdlib.file --name "$_file" --content "$_watch" --owner "${options[file_owner]}" --group "${options[file_group]}" --mode "${options[file_mode]}"
}

function consul.watch.update {
  consul.watch.delete
  consul.watch.create
}

function consul.watch.delete {
  stdlib.file --state absent --name "$_file"
}

function consul.watch.build_watch {
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
