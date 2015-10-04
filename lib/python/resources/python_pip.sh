# == Name
#
# python.pip
#
# === Description
#
# Manage a pip python package
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the pip package. Required.
# * version: The version of the pip package. Optional.
# * virtualenv: The virtual environment to put the package in. Required. Default: system.
# * url: A URL to install the package from. Optional.
# * owner: The owner of the virtualenv. Required. Default: root.
# * group: The group of the virtualenv. Required. Default: root.
# * index: Base URL of the python package index. Optional.
# * editable: If the package is installed as an editable resource. Required. Default: false.
# * environment: Additional environment variables. Optional.
# * install_args: Additional arguments to use when installing. Optional.
# * uninstall-args: Additional arguments to use when uninstalling. Optional.
#
# === Example
#
# ```shell
# python.pip --name minilanguage
# python.pip --name minilanguage --version 0.3.0
# python.pip --name minilanguage --version latest
# ```
#
# === Notes
#
# This resource is heavily based on puppet-python
#
function python.pip {
  stdlib.subtitle "python.pip"

  # Resource Options
  local -A options
  stdlib.options.create_option state       "present"
  stdlib.options.create_option name        "__required__"
  stdlib.options.create_option virtualenv  "system"
  stdlib.options.create_option owner       "root"
  stdlib.options.create_option group       "root"
  stdlib.options.create_option editable    "false"
  stdlib.options.create_option version
  stdlib.options.create_option url
  stdlib.options.create_option index
  stdlib.options.create_option environment
  stdlib.options.create_option install_args
  stdlib.options.create_option uninstall_args
  stdlib.options.parse_options "$@"

  # Local Variables
  local _user _group _cwd _pip _package _package_regex _pypi_index _editable _wheel _log _source _latest
  local _user_info=$(getent passwd "${options[owner]}")
  local _group_info=$(getent group "${options[group]}")

  # Internal Resource Configuration

  # Make sure the user exists
  if [[ -n "$_user_info" ]]; then
    stdlib.split "$_user_info" ':'
    _user="${options[owner]}"
  else
    stdlib.warn "User ${options[owner]} does not exist. Defaulting to root."
    _user="root"
  fi

  if [[ -n "$_group_info" ]]; then
    stdlib.split "$_group_info" ':'
    _group="${options[group]}"
  else
    stdlib.warn "Group ${options[group]} does not exist. Defaulting to root."
    _group="root"
  fi

  # Make sure `pip` exists
  if [[ "${options[virtualenv]}" == "system" ]]; then
    if ! stdlib.command_exists pip ; then
      stdlib.error "Cannot find pip command."
      if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
        exit 1
      else
        return 1
      fi
    else
      _pip="pip"
      _log="/tmp/pip.log"
      _cwd="/"
    fi
  else
    if [[ ! -f "${options[virtualenv]}/bin/pip" ]]; then
      stdlib.error "Cannot find pip comand"
      if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
        exit 1
      else
        return 1
      fi
    else
      _pip="${options[virtualenv]}/bin/pip"
      _log="${options[virtualenv]}/pip.log"
      _cwd="${options[virtualenv]}"
    fi
  fi

  # Build the pip package string
  if [[ -n "${options[version]}" && "${options[version]}" != "latest" ]]; then
    _package="${options[name]}==${options[version]}"
    _package_regex="^${options[name]}==${options[version]}$"
  else
    if [[ "${options[version]}" == "latest" ]]; then
      _latest="--upgrade"
    fi
    _package="${options[name]}"
    _package_regex="^${options[name]}"
  fi

  if [[ -n "${options[url]}" ]]; then
    if [[ -n "${options[version]}" && "${options[version]}" != "latest" ]]; then
      _source="${options[url]}@${options[version]}#egg=${options[name]}"
    else
      _source="${options[url]}#egg=${options[name]}"
    fi
  fi

  # Check for an alternate index
  if [[ -n "${options[index]}" ]]; then
    _pypi_index="--index-url=${options[index]}"
  fi

  # Check for editable
  if [[ "${options[editable]}" == "true" ]]; then
    _editable="-e"
  fi

  # Check for wheel support
  $_pip wheel --help &> /dev/null
  if [[ $? != 0 ]]; then
    _wheel="--no-use-wheel"
  fi

  # Process the resource
  stdlib.resource.process "python.pip" "${options[name]}"
}

function python.pip.read {
  local _current_state

  $_pip freeze | grep -i -q $_package_regex
  if [[ $? == 0 ]]; then
    stdlib_current_state="present"
  else
    stdlib_current_state="absent"
  fi

  # For now, to install the latest version, just try to install during each run
  if [[ -n "$_latest" ]]; then
    stdlib_current_state="absent"
  fi

}

function python.pip.create {
  local _cmd

  if [[ -n $_source ]]; then
    _cmd="$_pip --log $_log install $_latest ${options[install_args]} $_wheel $_pypi_index $_editable $_source"
  else
    _cmd="$_pip --log $_log install $_latest ${options[install_args]} $_wheel $_pypi_index $_editable $_package"
  fi

  stdlib.capture_error sudo -u $_user -g $_group "${options[environment]}" sh -c "cd $_cwd ; $_cmd"

}

function python.pip.update {
  python.pip.create
}

function python.pip.delete {
  local _cmd

  _cmd="echo y | $_pip --log $_log uninstall ${options[uninstall_args]} ${options[name]}"
  stdlib.capture_error sudo -u $_user -g $_group "${options[environment]}" sh -c "cd $_cwd ; $_cmd"
}
