# == Name
#
# git.repo
#
# === Description
#
# Manage a git repository
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name (path) of the git repo destination. Required.
# * source: The URI of the source git repo. Required.
# * branch: The branch to checkout. Optional. Default: master.
# * tag: The tag to checkout. Optional.
# * commit: the commit to checkout. Optional.
# * owner: The owner of the repo. Default: root.
# * group: The group owner of the repo. Default: root.
#
# === Example
#
# ```bash
# git.repo --state latest --name /root/.dotfiles --source https://github.com/jtopjian/dotfiles
# ```
#
# === Notes
#
# If state is set to "latest", Waffles will do a `git pull`, if it's able to.
#
# The order of checkout preferences is:
#
# * commit
# * tag
# * branch
#
git.repo() {
  # Declare the resource
  waffles_resource="git.repo"

  # Check if all dependencies are installed
  local _wrd=("git" "getent" "grep")
  if ! waffles.resource.check_dependencies "${_wrd[@]}" ; then
    return 1
  fi

  # Resource Options
  local -A options
  waffles.options.create_option state   "present"
  waffles.options.create_option name    "__required__"
  waffles.options.create_option source  "__required__"
  waffles.options.create_option branch  "master"
  waffles.options.create_option owner   "root"
  waffles.options.create_option group   "root"
  waffles.options.create_option commit
  waffles.options.create_option tag
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi


  # Local Variables
  local _uid=""
  local _gid=""
  local _user_info=""
  local _group_info=""

  # Internal Resource Configuration
  _user_info=$(getent passwd "${options[owner]}") || true
  if [[ -n $_user_info ]]; then
    string.split "$_user_info" ':'
    _uid="${__split[2]}"
  else
    log.warn "User ${options[owner]} does not exist. Defaulting to root."
    _uid=0
  fi

  _group_info=$(getent group "${options[group]}") || true
  if [[ -n $_group_info ]]; then
    string.split "$_group_info" ':'
    _gid="${__split[2]}"
  else
    log.warn "Group ${options[group]} does not exist. Defaulting to root."
    _gid=0
  fi

  # Process the resource
  waffles.resource.process $waffles_resource "${options[name]}"
}

git.repo.read() {
  local _wrcs=""
  local _return_code=""
  local _commit=""
  local _branch=""
  local _tag=""
  local _user_check=""
  local _group_check=""

  if [[ -f "${options[name]}/.git/config" ]]; then
    waffles.pushd "${options[name]}"

    # First check if state is set to "latest"
    if [[ ${options[state]} == "latest" ]]; then
      exec.mute git remote update || {
        log.error "Unable to update repository"
        waffles_resource_current_sttate="error"
        return 1
      }

      _return_code=$(git status -uno | grep -q up-to-date && echo $?) || true
      if [[ $_return_code == 0 ]]; then
        _wrcs="present"
      else
        _wrcs="update"
      fi

    # Next check if a commit was specified.
    # See if the repo is currently at that commit
    elif [[ -n ${options[commit]} ]]; then
      _commit=$(git rev-parse HEAD) || true
      if [[ -n $_commit && $_commit =~ ^${options[commit]} ]]; then
        _wrcs="present"
      else
        _wrcs="update"
      fi

    # If a commit was not specified, check for a tag
    elif [[ -n ${options[tag]} ]]; then
      _tag=$(git describe --always --tag) || true
      if [[ -n $_tag && ${options[tag]} == $_tag ]]; then
        _wrcs="present"
      else
        _wrcs="update"
      fi

    # Finally, check for a branch, defaulting to "master"
    else
      _branch=$(git rev-parse --abbrev-ref HEAD) || true
      if [[ -n $_branch && ${options[branch]} == "$_branch" ]]; then
        _wrcs="present"
      else
        _wrcs="update"
      fi
    fi
    waffles.popd

    _user_check=$(find "${options[name]}" ! -uid $_uid 2> /dev/null) || true
    if [[ -n $_user_check ]]; then
      _wrcs="update"
    fi

    _group_check=$(find "${options[name]}" ! -gid $_gid 2> /dev/null) || true
    if [[ -n $_group_check ]]; then
      _wrcs="update"
    fi
  fi

  if [[ -z $_wrcs ]]; then
    _wrcs="absent"
  fi

  waffles_resource_current_state="$_wrcs"
}

git.repo.create() {
  exec.capture_error git clone --quiet "${options[source]}" "${options[name]}"
  waffles.pushd "${options[name]}"

  # if a commit was given, check it out
  if [[ -n ${options[commit]} ]]; then
    exec.capture_error git checkout "${options[commit]}"

  # if a tag was given, check it out
  elif [[ -n ${options[tag]} ]]; then
    exec.capture_error git checkout "tags/${options[tag]}"

  # if a branch was given, check it out
  else
    exec.capture_error git checkout "${options[branch]}"
  fi
  waffles.popd


  # Make sure the owner and group are corrent
  exec.capture_error chown -R $_uid:$_gid "${options[name]}"
}

git.repo.update() {
  # If state is set to "latest", do a git pull
  waffles.pushd "${options[name]}"
  if [[ ${options[state]} == "latest" ]]; then
    if [[ -n ${options[branch]} ]]; then
      exec.capture_error git checkout "${options[branch]}"
    fi

    exec.capture_error git pull

  # If a commit was given, check it out
  elif [[ -n ${options[commit]} ]]; then
    exec.capture_error git checkout "${options[commit]}"

  # If a tag was given, check it out
  elif [[ -n ${options[tag]} ]]; then
    exec.capture_error git checkout "tags/${options[tag]}"

  # If a branch was given, check it out
  else
    exec.capture_error git checkout "${options[branch]}"
  fi

  waffles.popd

  # Make sure the owner and group are corrent
  exec.capture_error chown -R $_uid:$_gid "${options[name]}"
}

git.repo.delete() {
  os.directory --name "${options[name]}" --state absent
}
