# consul.get_nodes retrieves a list of nodes.
# Option: service. Required. Defaults to "all".
# Results are stored in consul_nodes hash.
function consul.get_nodes {
  local -A options
  stdlib.options.create_option service "all"
  stdlib.options.parse_options "$@"

  declare -Ag consul_nodes
  declare -g consul_error=""

  if [[ "${options[service]}" == "all" ]]; then
    if ! stdlib.command_exists curl ; then
      stdlib.error "Cannot find curl."
      if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
        exit 1
      else
        return 1
      fi
    fi

    local _nodes=$(curl -s http://localhost:8500/v1/catalog/nodes)
    if [[ "$_nodes" == "No known Consul servers" ]]; then
      consul_error="true"
      return 1
    else
      _nodes=$(echo "$_nodes" | tr -d []\" | sed -e 's/Node://g' | sed -e 's/Address://g' | sed -e 's/},{/#/g' | tr -d {})
      stdlib.split "$_nodes" "#"

      local _node
      for _node in "${__split[@]}"; do
        stdlib.split "$_node" ','
        consul_nodes[${__split[0]}]="${__split[1]}"
      done
    fi
  else
    if ! stdlib.command_exists dig ; then
      stdlib.error "Cannot find dig."
      if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
        exit 1
      else
        return 1
      fi
    fi

    local _node_result _node_info _node _name _port _address
    while read _node_result; do
      _node_info=($_node_result)
      _port="${_node_info[2]}"
      _node="${_node_info[3]}"
      _name=$(echo $_node | cut -d. -f1)
      _address=$(dig @localhost -p8600 $_node ANY +short | head -1)

      consul_nodes[$_name]="$_address"
      consul_nodes[$_name|port]="$_port"
    done < <(dig @localhost -p8600 ${options[service]}.service.consul SRV +short)

  fi
}

# get_services returns a list of services.
# Results are saved to consul_services array.
function consul.get_services {
  if ! stdlib.command_exists curl ; then
    stdlib.error "Cannot find curl."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  declare -ag consul_services=($(curl -s http://localhost:8500/v1/catalog/services | sed -e 's/\[.*\]//g' | tr -d {}\" | tr : " "))
}

function consul.get_kv {
  if ! stdlib.command_exists curl ; then
    stdlib.error "Cannot find curl."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  stdlib.options.create_option server "http://localhost:8500"
  stdlib.options.create_option path   "/v1/kv"
  stdlib.options.create_option key    "__required__"
  stdlib.options.create_option raw    "true"
  stdlib.options.parse_options "$@"

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
    stdlib.error "Error retrieving key: ${_result}"
  fi
}

function consul.set_kv {
  if ! stdlib.command_exists curl ; then
    stdlib.error "Cannot find curl."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  stdlib.options.create_option server "http://localhost:8500"
  stdlib.options.create_option path   "/v1/kv"
  stdlib.options.create_option key    "__required__"
  stdlib.options.create_option value  "__required__"
  stdlib.options.create_option flags
  stdlib.options.parse_options "$@"

  local _flags
  if [[ -n "${options[flags]}" ]]; then
    _flags="?flags=${options[flags]}"
  else
    _flags=""
  fi

  _result=$(curl -s -X PUT -d "${options[value]}" ${options[server]}${options[path]}/${options[key]}${_flags})
  if [[ "$_result" != "true" ]]; then
    stdlib.error "Error adding key: ${_result}"
    return 1
  fi
}

function consul.delete_kv {
  if ! stdlib.command_exists curl ; then
    stdlib.error "Cannot find curl."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  stdlib.options.create_option server "http://localhost:8500"
  stdlib.options.create_option path   "/v1/kv"
  stdlib.options.create_option key    "__required__"
  stdlib.options.parse_options "$@"

  _result=$(curl -s -X DELETE ${options[server]}${options[path]}/${options[key]})
  if [[ $? != 0 ]]; then
    stdlib.error "Error deleting key: ${_result}"
  fi
}
