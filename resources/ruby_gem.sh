# == Name
#
# ruby.gem
#
# === Description
#
# Manage a ruby gem.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the gem. Required.
# * version: The version of the gem. Optional.
# * url: A URL to install the gem from. Optional.
#
# === Example
#
# ```bash
# ruby.gem --name test-kitchen
# ```
#
ruby.gem() {
  # Declare the resource
  waffles_resource="ruby.gem"

  # Check if all dependencies are installed
  local _wrd=("gem" "grep")
  if ! waffles.resource.check_dependencies "${_wrd[@]}" ; then
    return 1
  fi

  # Resource Options
  local -A options
  waffles.options.create_option state       "present"
  waffles.options.create_option name        "__required__"
  waffles.options.create_option version
  waffles.options.create_option url
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi


  # Local Variables
  local _current_version
  local _latest_version
  local _gem_list_cmd="gem list"
  local _gem_install_cmd="gem install --no-rdoc --no-ri"
  local _gem_uninstall_cmd="gem uninstall"

  # Internal Resource Configuration
  if [[ -n ${options[url]} ]]; then
    _gem_install_cmd="$_gem_install_cmd --source ${options[url]}"
    _gem_list_cmd="$_gem_list_cmd --source ${options[url]}"
  fi

  waffles.resource.process $waffles_resource "${options[name]}"
}

ruby.gem.read() {
  local _current_state

  _current_version=$($_gem_list_cmd ^${options[name]}$ | grep ^${options[name]} | tr -d \(\), | cut -d" " -f2)
  if [[ -z $_current_version ]]; then
    _current_state="absent"
  else
    if [[ -n ${options[version]} ]]; then
      if [[ ${options[version]} == "latest" ]]; then
        _latest_version=$($_gem_list_cmd -r ^${options[name]}$ | grep ^${options[name]} | cut -d" " -f2 | tr -d \(\))
        if [[ $_latest_version != $_current_version ]]; then
          _current_state="update"
        fi
      else
        if [[ $_current_version != "${options[version]}" ]]; then
          log.info $_current_version
          log.info ${options[version]}
          _current_state="update"
        fi
      fi
    fi
  fi

  if [[ -n $_current_state ]]; then
    waffles_resource_current_state=$_current_state
  else
    waffles_resource_current_state="present"
  fi
}

ruby.gem.create() {
  if [[ -n ${options[version]} ]]; then
    if [[ ${options[version]} == "latest" ]]; then
      _gem_install_cmd="$_gem_install_cmd -v $_latest_version"
    else
      _gem_install_cmd="$_gem_install_cmd -v ${options[version]}"
    fi
  fi

  exec.capture_error "$_gem_install_cmd ${options[name]}"
}

ruby.gem.update() {
  ruby.gem.create
}

ruby.gem.delete() {
  if [[ -n ${options[version]} ]]; then
    _gem_uninstall_cmd="$_gem_uninstall_cmd -v ${options[version]}"
  fi

  exec.capture_error "$_gem_uninstall_cmd ${options[name]}"
}
