# == Name
#
# dnf.pkg
#
# === Description
#
# Manage packages via dnf.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * package: The name of the package, or the path to the rpm-file. Required.
# * version: The version of the package. Leave empty for first version found. Set to "latest" to always update.
#
# === Example
#
# ```bash
# dnf.pkg --package tmux --version latest
# dnf.pkg --package http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
# ```
#

dnf.pkg() {
  # Declare the resource
  waffles_resource="dnf.pkg"

  # Use dnf if available otherwise use yum
  local _dnf_cmd="dnf"
  if ! waffles.command_exists ${_dnf_cmd} ; then
    _dnf_cmd="yum"
  fi

  # Check if all dependencies are installed
  local _wrd=("${_dnf_cmd}" "rev")
  if ! waffles.resource.check_dependencies "${_wrd[@]}" ; then
    return 2
  fi

  # Resource Options
  local -A options
  waffles.options.create_option state   "present"
  waffles.options.create_option package "__required__"
  waffles.options.create_option version
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi

  # Local Variables
  local _installed
  local _in_updates
  local _version
  local _packagename

  # Process the resource
  waffles.resource.process $waffles_resource "${options[package]}"
}

dnf.pkg.read() {
  # check to see if it's a valid package, if it's an RPM file it's always valid
  if [[ ! ${options[package]} == *.rpm ]]; then
    # query the repo's to find the requested packagename
    /usr/bin/${_dnf_cmd} list ${options[package]}  2>&1 > /dev/null
    if [[ $? -ne 0 ]]; then
      log.error "No such package: ${options[package]}"
      waffles_resource_current_state="error"
      return
    fi
  else # if it's an rpm file
    if [[ -n ${options[version]} ]]; then
      log.error "if package is an rpm-file version may not be set."
      waffles_resource_current_state="error"
      return
    fi
  fi

  # The name of the package, if it's an rpm-file parse the path for the name
  _packagename="${options[package]}"
  if [[ ${options[package]} == *.rpm ]]; then
    _packagename=$(echo "${options[package]}" | rev | cut -d/ -f1 | rev | cut -d. -f1)
  fi
  log.debug "package name is: $_packagename"

  # Store the name of the package in $_installed, if it's installed
  _installed=$(/usr/bin/${_dnf_cmd} -q list installed $_packagename 2> /dev/null | tail -n1 | tr -s ' ' | cut -d' ' -f1)

  if [[ -z $_installed ]]; then
    waffles_resource_current_state="absent"
    return
  fi

  # If the package is installed and no version, then the requirement is satisfied
  if [[ -n $_installed && -z ${options[version]} ]]; then
    waffles_resource_current_state="present"
    return
  fi

  # If the latest package is required
  if [[ ${options[version]} == "latest" ]]; then
    # Check if the package is in the update list
    _in_updates=$(/usr/bin/${_dnf_cmd} -q list updates $_packagename 2> /dev/null | tail -n1 | tr -s ' ' | cut -d' ' -f1)
    if [[ -z $_in_updates ]]; then
      # If not in the update list return present
      waffles_resource_current_state="present"
      return
    else
      # If in the update list, return update
      waffles_resource_current_state="update"
      return
    fi
  # If a specific version is required
  else
    # Find the currently installed version
    _version=$(/usr/bin/${_dnf_cmd} -q list installed $_packagename 2> /dev/null | tail -n1 | tr -s ' ' | cut -d' ' -f2)
    log.debug "Installed version of $_packagename is: $_version"
    # If the prefixes of the versions are equal, return present
    # Example: requested version "1.8" equals rpm version "1.8.1-2.fc24"
    if [[ $_version == ${options[version]}* ]]; then
      waffles_resource_current_state="present"
      return
    else # if not return update
      waffles_resource_current_state="update"
      return
    fi
  fi

  waffles_resource_current_state="absent"
}

dnf.pkg.create() {
  local _dnf_version=""
  if [[ ${options[package]} != *.rpm && -n ${options[version]} && ${options[version]} != "latest" ]]; then
    _dnf_version="-${options[version]}"
  fi
  exec.capture_error "/usr/bin/${_dnf_cmd} -y install ${options[package]}${_$dnf_version}"
}

dnf.pkg.update() {
  local _dnf_version=""
  if [[ ${options[package]} != *.rpm && -n ${options[version]} && ${options[version]} != "latest" ]]; then
    _dnf_version="-${options[version]}"
  fi
  # Downgrade if installed version is greater than requested, else upgrade
  if [[ -n ${_version} && ${_version} > ${options[version]} ]]; then
    # Downgrades should be done by dnf history undo/rollback
    log.warn "downgrade requested, manual run of '${_dnf_cmd} history rollback' is preferred"
    exec.capture_error "/usr/bin/${_dnf_cmd} -y downgrade ${options[package]}${_dnf_version}"
  else
    exec.capture_error "/usr/bin/${_dnf_cmd} -y upgrade ${options[package]}${_dnf_version}"
  fi
}

dnf.pkg.delete() {
  exec.capture_error "/usr/bin/${_dnf_cmd} -y remove ${options[package]}"
}
