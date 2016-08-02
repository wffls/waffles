# == Name
#
# file.ini
#
# === Description
#
# Manages ini files/entries
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * file: The ini file. Required. This file _must_ exist already.
# * section: The ini file section. Use "__none__" to not use a section. Required.
# * option: The ini file setting/option. Required.
# * value: The value of the option. Use "__none__" to not set a value. Required.
#
# === Example
#
# ```bash
# file.ini --file /etc/nova/nova.conf --section DEFAULT --option debug --value True
# ```
#
file.ini() {
  # Declare the resource
  waffles_resource="file.ini"

  # Check if all dependencies are installed
  local _wrd=("sed" "grep")
  if ! waffles.resource.check_dependencies "${_wrd[@]}" ; then
    return 1
  fi

  # Resource Options
  local -A options
  waffles.options.create_option state   "present"
  waffles.options.create_option file    "__required__"
  waffles.options.create_option section "__required__"
  waffles.options.create_option option  "__required__"
  waffles.options.create_option value   "__required__"
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi

  # Ensure the file exists. Exit early if it doesn't.
  if [[ ! -f "${options[file]}" ]]; then
    log.error "${options[file]} does not exist."
    return 1
  fi

  # Local Variables
  local name="${options[file]}/${options[section]}/${options[option]}"

  # Process the resource
  waffles.resource.process $waffles_resource "$name"
}

file.ini.read() {
  if ! file.ini.ini_get_option ; then
    waffles_resource_current_state="absent"
    return
  fi

  if ! file.ini.ini_option_has_value ; then
    waffles_resource_current_state="update"
    return
  fi

  waffles_resource_current_state="present"
}

file.ini.create() {
  ini_file.set "${options[file]}" "${options[section]}" "${options[option]}" "${options[value]}"
}

file.ini.update() {
  ini_file.set "${options[file]}" "${options[section]}" "${options[option]}" "${options[value]}"
}

file.ini.delete() {
  ini_file.remove "${options[file]}" "${options[section]}" "${options[option]}"
}

# The following were modified from
# https://raw.githubusercontent.com/openstack-dev/devstack/master/inc/ini-config
file.ini.ini_get_option() {
  local _line=$(ini_file.get_option "${options[file]}" "${options[section]}" "${options[option]}")
  [[ -n $_line ]]
}

file.ini.ini_option_has_value() {
  ini_file.option_has_value "${options[file]}" "${options[section]}" "${options[option]}" "${options[value]}"
}
