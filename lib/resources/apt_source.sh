# == Name
#
# apt_source
#
# === Description
#
# Manage /etc/apt/sources.list.d entries.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The name of the apt repo. Required.
# * uri: The URI of the apt repo. Required.
# * distribution: The distribution of the apt repo. Required.
# * component: The component of the apt repo. Required.
# * include_src: Whether to include the source repo. Default: false.
# * refresh: run apt-get update if the source was modified. Default: true.
#
# === Example
#
# stdlib.apt_source --name lxc --uri http://ppa.launchpad.net/ubuntu-lxc/stable/ubuntu \
#                   --distribution trusty --component main
#
function stdlib.apt_source {
  stdlib.subtitle "stdlib.apt_source"

  local -A options
  stdlib.options.set_option state        "present"
  stdlib.options.set_option name         "__required__"
  stdlib.options.set_option uri          "__required__"
  stdlib.options.set_option distribution "__required__"
  stdlib.options.set_option component    "__required__"
  stdlib.options.set_option include_src  "false"
  stdlib.options.set_option refresh      "true"
  stdlib.options.parse_options "$@"

  stdlib.catalog.add "stdlib.apt_source/${options[name]}"

  stdlib.apt_source.read
  if [[ ${options[state]} == absent ]]; then
    if [[ $stdlib_current_state != absent ]]; then
      stdlib.info "${options[name]} state: $stdlib_current_state, should be absent."
      stdlib.apt_source.delete
    fi
  else
    case "$stdlib_current_state" in
      absent)
        stdlib.info "${options[name]} state: absent, should be present."
        stdlib.apt_source.create
        ;;
      present)
        stdlib.debug "${options[name]} state: present."
        ;;
    esac
  fi
}

function stdlib.apt_source.read {
  if [[ -f /etc/apt/sources.list.d/${options[name]}.list ]]; then
    stdlib_current_state="present"
    return
  fi

  stdlib_current_state="absent"
}

function stdlib.apt_source.create {
  stdlib.file --name /etc/apt/sources.list.d/${options[name]}.list --content "deb ${options[uri]} ${options[distribution]} ${options[component]}" --owner root --group root
  if [[ $options[include_src] == true ]]; then
    stdlib.file --name /etc/apt/sources.list.d/${options[name]}.list --content "deb-src ${options[uri]} ${options[distribution]} ${options[component]}" --owner root --group root
  fi

  if [[ ${options[refresh]} == true ]]; then
    stdlib.mute apt-get update
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}

function stdlib.apt_source.delete {
  stdlib.mute rm "/etc/apt/sources.list.d/${options[name]}.list"

  if [[ ${options[refresh]} == true ]]; then
    stdlib.mute apt-get update
  fi

  stdlib_state_change="true"
  stdlib_resource_change="true"
  let "stdlib_resource_changes++"
}
