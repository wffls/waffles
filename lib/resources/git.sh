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
# If state is set to "latest", Waffles will do a `git pull` if it's able to.
#
# The order of checkout preferences is:
#
# * commit
# * tag
# * branch
#
function stdlib.git {
  stdlib.subtitle "stdlib.git"

  local -A options
  stdlib.options.set_option state   "present"
  stdlib.options.set_option name    "__required__"
  stdlib.options.set_option source  "__required__"
  stdlib.options.set_option branch  "master"
  stdlib.options.set_option commit
  stdlib.options.set_option tag
  stdlib.options.set_option owner   "root"
  stdlib.options.set_option group   "root"
  stdlib.options.parse_options "$@"

  stdlib.catalog.add "stdlib.git/${options[name]}"

  if ! stdlib.command_exists git ; then
    stdlib.error "Cannot find git command."
    if [[ $WAFFLES_EXIT_ON_ERROR == true ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Check and make sure owner and group exist
  local _uid _gid
  local _user_info=$(getent passwd "${options[owner]}")
  if [[ -n $_user_info ]]; then
    stdlib.split "$_user_info" ':'
    _uid="${__split[2]}"
  else
    stdlib.warn "User ${options[owner]} does not exist. Defaulting to root."
    _uid=0
  fi

  local _group_info=$(getent group "${options[group]}")
  if [[ -n $_group_info ]]; then
    stdlib.split "$_group_info" ':'
    _gid="${__split[2]}"
  else
    stdlib.warn "Group ${options[group]} does not exist. Defaulting to root."
    _gid=0
  fi

  stdlib.git.read
  if [[ ${options[state]} == absent ]]; then
    if [[ $stdlib_current_state != absent ]]; then
      stdlib.info "${options[name]} state: $stdlib_current_state, should be absent."
      stdlib.git.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "${options[name]} state: absent, should be present."
        stdlib.git.create
        ;;
      present)
        stdlib.debug "${options[name]} state: present."
        ;;
      update)
        stdlib.info "${options[name]} state: out of date."
        stdlib.git.update
        ;;
    esac
  fi
}

function stdlib.git.read {
  if [[ -f ${options[name]}/.git/config ]]; then
    stdlib.debug_mute pushd "${options[name]}"

    # First check if state is set to "latest"
    if [[ ${options[state]} == "latest" ]]; then
      stdlib.debug_mute git remote update
      git status -uno | grep -q up-to-date
      if [[ $? -eq 0 ]]; then
        stdlib_current_state="present"
        return
      else
        stdlib_current_state="update"
        return
      fi

    # Next check if a commit was specified.
    # See if the repo is currently at that commit
    elif [[ -n ${options[commit]} ]]; then
      local _commit=$(git rev-parse HEAD)
      if [[ ${options[commit]} =~ ^${_commit} ]]; then
        stdlib_current_state="present"
        return
      else
        stdlib_current_state="update"
        return
      fi

    # If a commit was not specified, check for a tag
    elif [[ -n ${options[tag]} ]]; then
      local _tag=$(git describe --always --tag)
      if [[ ${options[tag]} == $_tag ]]; then
        stdlib_current_state="present"
        return
      else
        stdlib_current_state="update"
        return
      fi

    # Finally, check for a branch, defaulting to "master"
    else
      local _branch=$(git rev-parse --abbrev-ref HEAD)
      if [[ ${options[branch]} == $_branch ]]; then
        stdlib_current_state="present"
        return
      else
        stdlib_current_state="update"
      fi
    fi
    stdlib.debug_mute popd

    # Check if the uid / gid are out of sync
    user_info=$(getent passwd "${options[owner]}")

    local _user_check=$(find "${options[name]}" ! -uid $_uid 2> /dev/null)
    if [[ -n $_user_check ]]; then
      stdlib_current_state="update"
      return
    fi

    local _group_check=$(find "${options[name]}" ! -gid $_gid 2> /dev/null)
    if [[ -n $_group_check ]]; then
      stdlib_current_state="update"
      return
    fi
  fi

  stdlib_current_state="absent"
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

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
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

  # Make sure the owner and group are corrent
  stdlib.capture_error chown -R $_uid:$_gid "${options[name]}"

  stdlib.debug_mute popd
  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function stdlib.git.delete {
  stdlib.directory --name "${options[name]}" --state absent

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}
