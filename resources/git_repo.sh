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
  local _uid _gid
  local _user_info=$(getent passwd "${options[owner]}")
  local _group_info=$(getent group "${options[group]}")

  # Internal Resource Configuration
  if ! waffles.command_exists git ; then
    log.error "Cannot find git command."
    return 1
  fi

  if [[ -n $_user_info ]]; then
    string.split "$_user_info" ':'
    _uid="${__split[2]}"
  else
    log.warn "User ${options[owner]} does not exist. Defaulting to root."
    _uid=0
  fi

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
  local _current_state

  if [[ -f "${options[name]}/.git/config" ]]; then
    waffles.pushd "${options[name]}"

    # First check if state is set to "latest"
    if [[ ${options[state]} == "latest" ]]; then
      exec.mute git remote update
      git status -uno | grep -q up-to-date
      if [[ $? -eq 0 ]]; then
        _current_state="present"
      else
        _current_state="update"
      fi

    # Next check if a commit was specified.
    # See if the repo is currently at that commit
    elif [[ -n ${options[commit]} ]]; then
      local _commit=$(git rev-parse HEAD)
      if [[ ${options[commit]} =~ ^${_commit} ]]; then
        _current_state="present"
      else
        _current_state="update"
      fi

    # If a commit was not specified, check for a tag
    elif [[ -n ${options[tag]} ]]; then
      local _tag=$(git describe --always --tag)
      if [[ ${options[tag]} == $_tag ]]; then
        _current_state="present"
      else
        _current_state="update"
      fi

    # Finally, check for a branch, defaulting to "master"
    else
      local _branch=$(git rev-parse --abbrev-ref HEAD)
      if [[ ${options[branch]} == "$_branch" ]]; then
        _current_state="present"
      else
        _current_state="update"
      fi
    fi
    waffles.popd

    # Check if the uid / gid are out of sync
    user_info=$(getent passwd "${options[owner]}")

    local _user_check=$(find "${options[name]}" ! -uid $_uid 2> /dev/null)
    if [[ -n $_user_check ]]; then
      _current_state="update"
    fi

    local _group_check=$(find "${options[name]}" ! -gid $_gid 2> /dev/null)
    if [[ -n $_group_check ]]; then
      _current_state="update"
    fi
  fi

  if [[ -n $_current_state ]]; then
    waffles_resource_current_state="$_current_state"
  else
    waffles_resource_current_state="absent"
  fi
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
