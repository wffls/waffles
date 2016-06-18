# == Name
#
# apt.source
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
# apt.source --name lxc --uri http://ppa.launchpad.net/ubuntu-lxc/stable/ubuntu \
#                   --distribution trusty --component main
# ```
#
function apt.source {
  # Declare the resource
  waffles_resource="apt.source"

  # Resource Options
  local -A options
  waffles.options.create_option state        "present"
  waffles.options.create_option name         "__required__"
  waffles.options.create_option uri          "__required__"
  waffles.options.create_option distribution "__required__"
  waffles.options.create_option include_src  "false"
  waffles.options.create_option refresh      "true"
  waffles.options.create_option component
  waffles.options.parse_options "$@"
  if [[ $? != 0 ]]; then
    return $?
  fi


  # Process the resource
  waffles.resource.process $waffles_resource "${options[name]}"
}

function apt.source.read {
  if [[ -f "/etc/apt/sources.list.d/${options[name]}.list" ]]; then
    waffles_resource_current_state="present"
    return
  fi

  waffles_resource_current_state="absent"
}

function apt.source.create {
  os.file --name "/etc/apt/sources.list.d/${options[name]}.list" --content "deb ${options[uri]} ${options[distribution]} ${options[component]}" --owner root --group root
  if [[ ${options[include_src]} == "true" ]]; then
    os.file --name "/etc/apt/sources.list.d/${options[name]}-src.list" --content "deb-src ${options[uri]} ${options[distribution]} ${options[component]}" --owner root --group root
  fi

  if [[ ${options[refresh]} == "true" ]]; then
    exec.mute apt-get update
  fi
}

function apt.source.delete {
  exec.capture_error rm "/etc/apt/sources.list.d/${options[name]}.list"

  if [[ ${options[refresh]} == "true" ]]; then
    exec.mute apt-get update
  fi
}
