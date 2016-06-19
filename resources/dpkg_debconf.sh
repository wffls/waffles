# == Name
#
# dpkg.debconf
#
# === Description
#
# Manages debconf entries
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * package: The package to configure. Required.
# * question: The debconf question. Required.
# * vtype: The vtype of the debconf setting. Required.
# * value: The answer/setting. Required.
#
# === Example
#
# ```shell
# dpkg.debconf --package mysql-server --question mysql-server/root_password
#                --vtype password --value mypassword
# ```
#
dpkg.debconf() {
  # Declare the resource
  waffles_resource="dpkg.debconf"

  # Resource Options
  local -A options
  waffles.options.create_option state    "present"
  waffles.options.create_option package  "__required__"
  waffles.options.create_option question "__required__"
  waffles.options.create_option vtype    "__required__"
  waffles.options.create_option value    "__required__"
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi


  # Local Variables
  local _value _name

  # Internal Resource Configuration
  if ! waffles.command_exists "debconf-set-selections" ; then
    log.error "Cannot find command: debconf-set-selections."
    return 1
  fi

  if [[ -n ${options[unseen]} ]]; then
    _unseen="-u"
  else
    _unseen=""
  fi

  _name="${options[package]}/${options[question]}/${options[vtype]}"

  # Process the resource
  waffles.resource.process $waffles_resource "$_name"
}

dpkg.debconf.read() {
  local _dc=$(echo get ${options[question]} | debconf-communicate ${options[package]} 2>/dev/null)
  if [[ $_dc =~ ^10 ]]; then
    waffles_resource_current_state="absent"
  elif [[ $_dc == "0" ]]; then
    waffles_resource_current_state="absent"
  elif [[ $_dc == "0 ${options[value]}" ]]; then
    waffles_resource_current_state="present"
  else
    waffles_resource_current_state="update"
  fi
}

dpkg.debconf.create() {
  local _script
  read -r -d '' _script<<EOF
echo ${options[package]} ${options[question]} ${options[vtype]} "${options[value]}" | debconf-set-selections
EOF
  exec.capture_error "$_script"
}

dpkg.debconf.update() {
  dpkg.debconf.delete
  dpkg.debconf.create
}

dpkg.debconf.delete() {
  local _script
  read -r -d '' _script<<EOF
echo RESET ${options[question]} | debconf-communicate ${options[package]}
EOF
  exec.capture_error "$_script"
}
