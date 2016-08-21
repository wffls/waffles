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
# ```bash
# python.virtualenv --name foo
# ```
#
# === Notes
#
# This resource is heavily based on puppet-python
#
python.virtualenv() {
  # Declare the resource
  waffles_resource="python.virtualenv"

  # Check if all dependencies are installed
  local _wrd=("getent" "virtualenv" "sudo")
  if ! waffles.resource.check_dependencies "${_wrd[@]}" ; then
    return 2
  fi

  # Resource Options
  local -A options
  waffles.options.create_option state        "present"
  waffles.options.create_option name         "__required__"
  waffles.options.create_option venv_dir     "/usr/local"
  waffles.options.create_option systempkgs   "false"
  waffles.options.create_option distribute   "distribute"
  waffles.options.create_option owner        "root"
  waffles.options.create_option group        "root"
  waffles.options.create_option mode         "755"
  waffles.options.create_option requirements
  waffles.options.create_option index
  waffles.options.create_option environment
  waffles.options.create_option pip_args
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi


  # Local Variables
  local _user _group _pypi_index _system_pkg _pip _venv _log _wheel
  local _user_info=$(getent passwd "${options[owner]}")
  local _group_info=$(getent group "${options[group]}")

  # Internal Resource Configuration
  # Make sure the user exists
  if [[ -n "$_user_info" ]]; then
    string.split "$_user_info" ':'
    _user="${options[owner]}"
  else
    log.warn "User ${options[owner]} does not exist. Defaulting to root."
    _user="root"
  fi

  if [[ -n "$_group_info" ]]; then
    string.split "$_group_info" ':'
    _group="${options[group]}"
  else
    log.warn "Group ${options[group]} does not exist. Defaulting to root."
    _group="root"
  fi

  # Make sure the venv_dir exists
  if [[ ! -d "${options[venv_dir]}" ]]; then
    log.error "${options[venv_dir]} does not exist."
    return 1
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
  waffles.resource.process $waffles_resource "${options[name]}"
}

python.virtualenv.read() {
  if [[ -f "$_venv/bin/activate" ]]; then
    waffles_resource_current_state="present"
  else
    waffles_resource_current_state="absent"
  fi
}

python.virtualenv.create() {
  local _cmd _wheel

  os.directory --name $_venv --owner $_user --group $_group --mode ${options[mode]}
  exec.capture_error sudo -u $_user -g $_group "${options[environment]}" virtualenv $_system_pkg -p python $_venv
  if [[ $? == 0 ]]; then
    # check for wheel support
    exec.capture_error sudo -u $_user -g $_group "${options[environment]}" sh -c "cd $_venv ; $_pip wheel --help &> /dev/null"
    if [[ $? != 0 ]]; then
      _wheel="--no-use-wheel"
    fi

    _cmd="$_pip --log $_log install $_pypi_index $_wheel --upgrade pip ${options[distribute]}"
    exec.capture_error sudo -u $_user -g $_group $_environment sh -c "cd $_venv ; $_cmd"

    if [[ -n "${options[requirements]}" ]]; then
      _cmd="$_pip --log $_log install $_pypi_index $_wheel -r ${options[requirements]} ${options[pip_args]}"
      exec.capture_error sudo -u $_user -g $_group $_environment sh -c "cd $_venv ; $_cmd"
    fi
  fi
}

python.virtualenv.update() {
  python.virtualenv.create
}

python.virtualenv.delete() {
  local _cmd

  exec.capture_error rm -rf "$_venv"
}
