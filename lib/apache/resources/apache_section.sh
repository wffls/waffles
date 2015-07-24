# == Name
#
# apache.section
#
# === Description
#
# Manages an apache section.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * type: The type of the section Required. namevar.
# * name: The name of the section Required. namevar.
# * path: The path leading up to the type. Optional. Multi. namevar.
# * file: The file to store the settings in. Optional. Defaults to /etc/apache2/apache2.conf. namevar.
#
# === Example
#
# ```shell
# apache.section --type Directory --name /
# apache.section --path "VirtualHost=*:80" --type Directory --name /
# ```
#
function apache.section {
  stdlib.subtitle "apache.section"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  local -A options
  local -a path
  stdlib.options.create_option state   "present"
  stdlib.options.create_option type    "__required__"
  stdlib.options.create_option name    "__required__"
  stdlib.options.create_option file    "/etc/apache2/apache2.conf"
  stdlib.options.create_mv_option path
  stdlib.options.parse_options "$@"

  local _path
  local _parent_path
  local -a _parent_paths
  local _file="${options[file]}"
  local _name="$_file"

  if [[ $(stdlib.array_length path) -gt 0 ]]; then
    for p in "${path[@]}"; do
      stdlib.split "$p" "="
      _parent_paths+=("${__split[0]}/arg[. = '${__split[1]}']")
      _name="${_name}.${p}"
    done
    _parent_path=$(stdlib.array_join "_parent_paths" "/../")
    _path="${_parent_path}/.."
  fi

  _name="${_name}.${options[type]}"

  stdlib.catalog.add "apache.section/$_name"

  apache.section.read
  if [[ "${options[state]}" == "absent" ]]; then
    if [[ "$stdlib_current_state" != "absent" ]]; then
      stdlib.info "$_name state: $stdlib_current_state, should be absent."
      apache.section.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "$_name state: absent, should be present."
        apache.section.create
        ;;
      present)
        stdlib.debug "$_name state: present."
        ;;
      error)
        stdlib.error "$_name state: parent does not exist yet. Please create it first."
        return
        ;;
    esac
  fi
}

function apache.section.read {
  local _result

  if [[ ! -f "$_file" ]]; then
    stdlib_current_state="absent"
    return
  fi

  # Check if the parent type/name exists
  if [[ -n "$_path" ]]; then
    _result=$(augeas.get --lens Httpd --file "$_file" --path "$_parent_path")
    if [[ "$_result" == "absent" ]]; then
      stdlib_current_state="error"
      return
    fi
  fi

  # Check if the type exists
  stdlib_current_state=$(augeas.get --lens Httpd --file "$_file" --path "$_path/${options[type]}/arg[. = '${options[name]}']")
  if [[ "$stdlib_current_state" == "absent" ]]; then
    return
  fi

  stdlib_current_state="present"
}

function apache.section.create {
  local _dir=$(dirname "$_file")
  if [[ ! -d "$_dir" ]]; then
    stdlib.capture_error mkdir -p "$_dir"
  fi

  local -a _augeas_commands=()
  _augeas_commands+=("set /files$_file/$_path/${options[type]}/arg '${options[name]}'")
  local _result=$(augeas.run --lens Httpd --file "$_file" "${_augeas_commands[@]}")

  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error adding apache.section $_name with augeas: $_result"
    return
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function apache.section.delete {
  local -a _augeas_commands=()
  _augeas_commands+=("rm /files$_file/$_path/${options[type]}/arg[. = '${options[name]}']")

  local _result=$(augeas.run --lens Httpd --file "$_file" "${_augeas_commands[@]}")

  if [[ "$_result" =~ ^error ]]; then
    stdlib.error "Error deleting apache.section $_name with augeas: $_result"
    return
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}
