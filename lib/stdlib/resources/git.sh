# == Name
#
# stdlib.git
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
# ```shell
# git --state latest --name /root/.dotfiles --source https://github.com/jtopjian/dotfiles
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
function stdlib.git {
  stdlib.subtitle "stdlib.git"

  if ! stdlib.command_exists git ; then
    stdlib.error "Cannot find git command."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  stdlib.options.create_option state   "present"
  stdlib.options.create_option name    "__required__"
  stdlib.options.create_option source  "__required__"
  stdlib.options.create_option branch  "master"
  stdlib.options.create_option owner   "root"
  stdlib.options.create_option group   "root"
  stdlib.options.create_option commit
  stdlib.options.create_option tag
  stdlib.options.parse_options "$@"

  # Local Variables
  local _uid _gid
  local _user_info=$(getent passwd "${options[owner]}")
  local _group_info=$(getent group "${options[group]}")

  # Internal Resource Configuration
  if [[ -n $_user_info ]]; then
    stdlib.split "$_user_info" ':'
    _uid="${__split[2]}"
  else
    stdlib.warn "User ${options[owner]} does not exist. Defaulting to root."
    _uid=0
  fi

  if [[ -n $_group_info ]]; then
    stdlib.split "$_group_info" ':'
    _gid="${__split[2]}"
  else
    stdlib.warn "Group ${options[group]} does not exist. Defaulting to root."
    _gid=0
  fi

  # Process the resource
  stdlib.resource.process "stdlib.git" "${options[name]}"
}

function stdlib.git.read {
  local _current_state

  if [[ -f "${options[name]}/.git/config" ]]; then
    stdlib.debug_mute pushd "${options[name]}"

    # First check if state is set to "latest"
    if [[ ${options[state]} == "latest" ]]; then
      stdlib.debug_mute git remote update
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
      if [[ ${options[branch]} == $_branch ]]; then
        _current_state="present"
      else
        _current_state="update"
      fi
    fi
    stdlib.debug_mute popd

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
    stdlib_current_state="$_current_state"
  else
    stdlib_current_state="absent"
  fi
}

function stdlib.git.create {
  stdlib.capture_error git clone --quiet "${options[source]}" "${options[name]}"
  stdlib.debug_mute pushd "${options[name]}"

  # if a commit was given, check it out
  if [[ -n ${options[commit]} ]]; then
    stdlib.capture_error git checkout "${options[commit]}"

  # if a tag was given, check it out
  elif [[ -n ${options[tag]} ]]; then
    stdlib.capture_error git checkout "tags/${options[tag]}"

  # if a branch was given, check it out
  else
    stdlib.capture_error git checkout "${options[branch]}"
  fi
  stdlib.debug_mute popd


  # Make sure the owner and group are corrent
  stdlib.capture_error chown -R $_uid:$_gid "${options[name]}"
}

function stdlib.git.update {
  # If state is set to "latest", do a git pull
  stdlib.debug_mute pushd "${options[name]}"
  if [[ ${options[state]} == "latest" ]]; then
    if [[ -n ${options[branch]} ]]; then
      stdlib.capture_error git checkout "${options[branch]}"
    fi

    stdlib.capture_error git pull

  # If a commit was given, check it out
  elif [[ -n ${options[commit]} ]]; then
    stdlib.capture_error git checkout "${options[commit]}"

  # If a tag was given, check it out
  elif [[ -n ${options[tag]} ]]; then
    stdlib.capture_error git checkout "tags/${options[tag]}"

  # If a branch was given, check it out
  else
    stdlib.capture_error git checkout "${options[branch]}"
  fi

  stdlib.debug_mute popd

  # Make sure the owner and group are corrent
  stdlib.capture_error chown -R $_uid:$_gid "${options[name]}"
}

function stdlib.git.delete {
  stdlib.directory --name "${options[name]}" --state absent
}
