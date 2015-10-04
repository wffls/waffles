# == Name
#
# python.virtualenv
#
# === Description
#
# Manage a python virtualenv
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the virtualenv package. Required.
# * venv_dir: The path / parent directory to the virtual environment. Required. Default: /usr/local"
# * requirements: The path to a requirements.txt file. Optional.
# * systempkgs: Copy system site-packages into the virtualenv. Required. Default: false.
# * distribute: Distribute method. Required. Default: distribute
# * index: An alternative pypi index file. Optional.
# * owner: The owner of the virtualenv. Required. Default: root.
# * group: The group of the virtualenv. Required. Default: root.
# * mode: The directory mode of the venv. Required. Default: 755.
# * environment: Additional environment variables. Optional.
# * pip_args: Extra pip args. Optional.
# === Example
#
# ```shell
# python.virtualenv --name foo
# ```
#
# === Notes
#
# This resource is heavily based on puppet-python
#
function python.virtualenv {
  stdlib.subtitle "python.virtualenv"

  # Ensure virtualenv exists
  if ! stdlib.command_exists virtualenv ; then
    stdlib.error "python not found."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  stdlib.options.create_option state        "present"
  stdlib.options.create_option name         "__required__"
  stdlib.options.create_option venv_dir     "/usr/local"
  stdlib.options.create_option systempkgs   "false"
  stdlib.options.create_option distribute   "distribute"
  stdlib.options.create_option owner        "root"
  stdlib.options.create_option group        "root"
  stdlib.options.create_option mode         "755"
  stdlib.options.create_option requirements
  stdlib.options.create_option index
  stdlib.options.create_option environment
  stdlib.options.create_option pip_args
  stdlib.options.parse_options "$@"

  # Local Variables
  local _user _group _pypi_index _system_pkg _pip _venv _log _wheel
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

  # Make sure the venv_dir exists
  if [[ ! -d "${options[venv_dir]}" ]]; then
    stdlib.error "${options[venv_dir]} does not exist."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Configure the venv path
  _venv="${options[venv_dir]}/${options[name]}"

  # Check for an alternate index
  if [[ -n "${options[index]}" ]]; then
    _pypi_index="-i ${options[index]}"
  fi

  # Configure system package flags
  if [[ "${options[systempkgs]}" == "true" ]]; then
    _system_pkg="--system-site-packages"
  else
    _system_pkg="--no-site-packages"
  fi

  # Configure the pip command
  _pip="$_venv/bin/pip"
  _log="$_venv/pip.log"

  # Process the resource
  stdlib.resource.process "python.virtualenv" "${options[name]}"
}

function python.virtualenv.read {
  if [[ -f "$_venv/bin/activate" ]]; then
    stdlib_current_state="present"
  else
    stdlib_current_state="absent"
  fi
}

function python.virtualenv.create {
  local _cmd _wheel

  stdlib.directory --name $_venv --owner $_user --group $_group --mode ${options[mode]}
  stdlib.capture_error sudo -u $_user -g $_group "${options[environment]}" virtualenv $_system_pkg -p python $_venv
  if [[ $? == 0 ]]; then
    # check for wheel support
    stdlib.capture_error sudo -u $_user -g $_group "${options[environment]}" sh -c "cd $_venv ; $_pip wheel --help &> /dev/null"
    if [[ $? != 0 ]]; then
      _wheel="--no-use-wheel"
    fi

    _cmd="$_pip --log $_log install $_pypi_index $_wheel --upgrade pip ${options[distribute]}"
    stdlib.capture_error sudo -u $_user -g $_group $_environment sh -c "cd $_venv ; $_cmd"

    if [[ -n "${options[requirements]}" ]]; then
      _cmd="$_pip --log $_log install $_pypi_index $_wheel -r ${options[requirements]} ${options[pip_args]}"
      stdlib.capture_error sudo -u $_user -g $_group $_environment sh -c "cd $_venv ; $_cmd"
    fi
  fi
}

function python.virtualenv.update {
  python.virtualenv.create
}

function python.virtualenv.delete {
  local _cmd

  stdlib.capture_error rm -rf "$_venv"
}
