# == Name
#
# stdlib.apt
#
# === Description
#
# Manage packages via apt.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * package: The name of the package. Required. namevar.
# * version: The version of the package. Leave empty for first version found. Set to "latest" to always update.
#
# === Example
#
# ```shell
# stdlib.apt --package tmux --version latest
# ```
#
function stdlib.apt {
  stdlib.subtitle "stdlib.apt"

  local -A options
  stdlib.options.create_option state   "present"
  stdlib.options.create_option package "__required__"
  stdlib.options.create_option version
  stdlib.options.parse_options "$@"

  stdlib.catalog.add "stdlib.apt/${options[package]}"

  local _installed _candidate _version

  if [[ -z "${options[version]}" ]]; then
    _version=""
  elif [[ "${options[version]}" == latest ]]; then
    _version=""
  else
    _version="${options[version]}"
  fi

  stdlib.apt.read
  if [[ "${options[state]}" == "absent" ]]; then
    if [[ "$stdlib_current_state" != "absent" ]]; then
      stdlib.info "$package state: $stdlib_current_state, should be absent."
      stdlib.apt.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "${options[package]} state: absent, should be installed."
        stdlib.apt.install
        ;;
      present)
        stdlib.debug "${options[package]} state: present."
        ;;
      update)
        stdlib.info "${options[package]} state: out of date."
        stdlib.apt.install
        ;;
      updateable)
        stdlib.info "${options[package]} state: present, new version available."
        ;;
    esac
  fi
}

function stdlib.apt.read {
  # check to see if it's a valid package
  # apt-cache is handling stderr weird
  # return 1 so installation attempt does not happen
  exist=$(apt-cache policy ${options[package]})
  if [[ -z "$exist" ]]; then
    stdlib.info "No such package: ${options[package]}"
    stdlib_current_state="unknown"
    return
  fi

  # check to see if it's installed at all
  stdlib.debug_mute dpkg -s ${options[package]}
  if [[ $? == 1 ]]; then
    stdlib_current_state="absent"
    return
  fi

  _installed=$(/usr/bin/apt-cache policy ${options[package]} | grep Installed | cut -d: -f2- | sed -e 's/^[[:space:]]//g')
  _candidate=$(/usr/bin/apt-cache policy ${options[package]} | grep Candidate | cut -d: -f2- | sed -e 's/^[[:space:]]//g')

  # If the package is installed, but version is set to "", then the requirement is satisfied
  if [[ -n "$_installed" && -z "${options[version]}" ]]; then
    stdlib_current_state="present"
    return
  fi

  # if version == latest, install if there's a newer version available
  if [[ "${options[version]}" == "latest" && "$_installed" != "$_candidate" ]]; then
    stdlib_current_state="update"
    _version="$_candidate"
    return
  fi

  # if installed != version, install the package
  if [[ "${options[version]}" != "latest" && "$_installed" != "${options[version]}" ]]; then
    stdlib_current_state="update"
    return
  fi

  # if installed and candidate differ, report a new version available.
  if [[ "$_installed" != "$_candidate" ]]; then
    stdlib.debug "New version available: $_candidate"
  fi

  stdlib_current_state="present"
}

function stdlib.apt.install {
  export DEBIAN_FRONTEND=noninteractive
  export APT_LISTBUGS_FRONTEND=none
  export APT_LISTCHANGES_FRONTEND=none
  stdlib.capture_error "/usr/bin/apt-get install -y --force-yes -o DPkg::Options::=--force-confold ${options[package]}=${_version}"
  unset DEBIAN_FRONTEND
  unset APT_LISTBUGS_FRONTEND
  unset APT_LISTCHANGES_FRONTEND

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function stdlib.apt.delete {
  export DEBIAN_FRONTEND=noninteractive
  export APT_LISTBUGS_FRONTEND=none
  export APT_LISTCHANGES_FRONTEND=none
  stdlib.capture_error "/usr/bin/apt-get purge -q -y ${options[package]}"
  unset DEBIAN_FRONTEND
  unset APT_LISTBUGS_FRONTEND
  unset APT_LISTCHANGES_FRONTEND

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}
