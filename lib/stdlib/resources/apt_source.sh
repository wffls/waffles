# == Name
#
# stdlib.apt_source
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
# * component: The component of the apt repo. Optional.
# * include_src: Whether to include the source repo. Default: false.
# * refresh: run apt-get update if the source was modified. Default: true.
#
# === Example
#
# ```shell
# stdlib.apt_source --name lxc --uri http://ppa.launchpad.net/ubuntu-lxc/stable/ubuntu \
#                   --distribution trusty --component main
# ```
#
function stdlib.apt_source {
  stdlib.subtitle "stdlib.apt_source"

  # Resource Options
  local -A options
  stdlib.options.create_option state        "present"
  stdlib.options.create_option name         "__required__"
  stdlib.options.create_option uri          "__required__"
  stdlib.options.create_option distribution "__required__"
  stdlib.options.create_option include_src  "false"
  stdlib.options.create_option refresh      "true"
  stdlib.options.create_option component
  stdlib.options.parse_options "$@"

  # Process the resource
  stdlib.resource.process "stdlib.apt_source" "${options[name]}"
}

function stdlib.apt_source.read {
  if [[ -f "/etc/apt/sources.list.d/${options[name]}.list" ]]; then
    stdlib_current_state="present"
    return
  fi

  stdlib_current_state="absent"
}

function stdlib.apt_source.create {
  stdlib.file --name "/etc/apt/sources.list.d/${options[name]}.list" --content "deb ${options[uri]} ${options[distribution]} ${options[component]}" --owner root --group root
  if [[ ${options[include_src]} == "true" ]]; then
    stdlib.file --name "/etc/apt/sources.list.d/${options[name]}-src.list" --content "deb-src ${options[uri]} ${options[distribution]} ${options[component]}" --owner root --group root
  fi

  if [[ ${options[refresh]} == "true" ]]; then
    stdlib.mute apt-get update
  fi
}

function stdlib.apt_source.delete {
  stdlib.capture_error rm "/etc/apt/sources.list.d/${options[name]}.list"

  if [[ ${options[refresh]} == "true" ]]; then
    stdlib.mute apt-get update
  fi
}
