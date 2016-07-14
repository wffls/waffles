# == Name
#
# dnf.copr
#
# === Description
#
# Manages copr repositories
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The user name of the copr repo. rhscl in rhscl/perl516. Required.
# * project: The project name of the copr repo. perl516 in rhscl/perl516. Required.
#
# === Example
#
# ```bash
# dnf.copr --name rhscl --project perl516
# ```
#
dnf.copr() {
  # Declare the resource
  waffles_resource="dnf.copr"

  # Use dnf if available otherwise use yum
  local _dnf_cmd="dnf"
  if ! waffles.command_exists ${_dnf_cmd} ; then
    if [ -f /usr/lib/yum-plugins/copr.py ]; then
      log.error "yum needs the package 'yum-plugin-copr' for copr support"
      return 1
    fi
    _dnf_cmd="yum"
  fi

  # Check if all dependencies are installed
  local _wrd=("${_dnf_cmd}" "grep" "sed")
  if ! waffles.resource.check_dependencies "${_wrd[@]}" ; then
    return 1
  fi

  # Resource Options
  local -A options
  waffles.options.create_option state    "present"
  waffles.options.create_option name     "__required__"
  waffles.options.create_option project  "__required__"
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi

  local _copr="${options[name]}/${options[project]}"

  # Process the resource
  waffles.resource.process $waffles_resource "$_copr"
}

dnf.copr.read() {
  local _repo_file_name="_copr_$(echo $_copr | sed -e "s|[/:]|-|" -e "s|\.|_|").repo"
  if [ -f /etc/yum.repos.d/$_repo_file_name ]; then
    local _is_enabled=$(grep ^enabled= /etc/yum.repos.d/$_repo_file_name | cut -d= -f2)
    if [[ ${_is_enabled} -eq 1 ]]; then
      waffles_resource_current_state="present"
    else
      waffles_resource_current_state="absent"
    fi
    return
  fi

  waffles_resource_current_state="absent"
}

dnf.copr.create() {
  exec.capture_error /usr/bin/${_dnf_cmd} -y copr enable $_copr
}

dnf.copr.delete() {
  exec.capture_error /usr/bin/${_dnf_cmd} -y copr disable $_copr
}
