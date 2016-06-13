# consul.get_nodes returns a list of node names.
# Options:
#   service. Required. Defaults to "all".
# Results are stored in __consul_nodes hash.
function consul.get_nodes {
  declare -Ag __consul_nodes
  local -A options
  waffles.options.create_option service "all"
  waffles.options.parse_options "$@"

  declare -g consul_error=""

  if [[ ${options[service]} == "all" ]]; then
    if ! waffles.command_exists curl ; then
      log.error "Cannot find curl."
      return 1
    fi

    local _nodes=$(curl -s http://localhost:8500/v1/catalog/nodes)
    if [[ $_nodes == "No known Consul servers" ]]; then
      consul_error="true"
      return 1
    else
      _nodes=$(echo "$_nodes" | tr -d []\" | sed -e 's/Node://g' | sed -e 's/Address://g' | sed -e 's/},{/#/g' | tr -d {})
      string.split "$_nodes" "#"

      local _node
      for _node in "${__split[@]}"; do
        string.split "$_node" ','
        __consul_nodes[${__split[0]}]="${__split[1]}"
      done
    fi
  else
    if ! waffles.command_exists dig ; then
      log.error "Cannot find dig."
      return 1
    fi

    local _node_result _node_info _node _name _port _address
    while read _node_result; do
      _node_info=($_node_result)
      _port="${_node_info[2]}"
      _node="${_node_info[3]}"
      _name=$(echo $_node | cut -d. -f1)
      _address=$(dig @localhost -p8600 $_node ANY +short | head -1)

      __consul_nodes[$_name]="$_address"
    done < <(dig @localhost -p8600 ${options[service]}.service.consul SRV +short)

  fi
}

# get_services returns a list of services.
# Results are saved to consul_services array.
function consul.get_services {
  if ! waffles.command_exists curl ; then
    log.error "Cannot find curl."
    return 1
  fi

  declare -ag consul_services=($(curl -s http://localhost:8500/v1/catalog/services | sed -e 's/\[.*\]//g' | tr -d {}\" | tr : " "))
}

# get_kv returns the value for a given key in the key/value store
# Options:
#   server: The consul server to query. Defaults to localhost:8500
#   path: The path to query. Defaults to /v1/kv.
#   key: The key to query. Required.
#   raw: Whether to return a raw result. Defaults to "true".
function consul.get_kv {
  if ! waffles.command_exists curl ; then
    log.error "Cannot find curl."
    return 1
  fi

  local -A options
  waffles.options.create_option server "http://localhost:8500"
  waffles.options.create_option path   "/v1/kv"
  waffles.options.create_option key    "__required__"
  waffles.options.create_option raw    "true"
  waffles.options.parse_options "$@"

  local _raw
  if [[ "${options[raw]}" == "true" ]]; then
    _raw="?raw"
  else
    _raw=""
  fi

  _result=$(curl -s ${options[server]}${options[path]}/${options[key]}${_raw})
  if [[ $? == 0 ]]; then
    echo "$_result"
  else
    log.error "Error retrieving key: ${_result}"
  fi
}

# set_kv sets a value for a given key in the key/value store
# Options:
#   server: The consul server to use. Defaults to localhost:8500
#   path: The path to the key. Defaults to /v1/kv.
#   key: The key to set. Required.
#   value: The value to set. Required.
#   flags: Additional flags.
function consul.set_kv {
  if ! waffles.command_exists curl ; then
    log.error "Cannot find curl."
    return 1
  fi

  local -A options
  waffles.options.create_option server "http://localhost:8500"
  waffles.options.create_option path   "/v1/kv"
  waffles.options.create_option key    "__required__"
  waffles.options.create_option value  "__required__"
  waffles.options.create_option flags
  waffles.options.parse_options "$@"

  local _flags
  if [[ -n ${options[flags]} ]]; then
    _flags="?flags=${options[flags]}"
  else
    _flags=""
  fi

  _result=$(curl -s -X PUT -d "${options[value]}" ${options[server]}${options[path]}/${options[key]}${_flags})
  if [[ $_result != "true" ]]; then
    log.error "Error adding key: ${_result}"
    return 1
  fi
}

# delete_kv deletes a key in the key/value store.
# Options:
#   server: The consul server to use. Defaults to localhost:8500
#   path: The path to the key. Defaults to /v1/kv.
#   key: The key to delete. Required.
function consul.delete_kv {
  if ! waffles.command_exists curl ; then
    log.error "Cannot find curl."
    return 1
  fi

  local -A options
  waffles.options.create_option server "http://localhost:8500"
  waffles.options.create_option path   "/v1/kv"
  waffles.options.create_option key    "__required__"
  waffles.options.parse_options "$@"

  _result=$(curl -s -X DELETE ${options[server]}${options[path]}/${options[key]})
  if [[ $? != 0 ]]; then
    log.error "Error deleting key: ${_result}"
  fi
}
