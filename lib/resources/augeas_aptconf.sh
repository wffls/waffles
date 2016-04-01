# == Name
#
# augeas.aptconf
#
# === Description
#
# Manages apt.conf settings
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * setting: The setting Required. namevar.
# * value: A value for the setting Required.
# * file: The file to add the variable to. Required. namevar.
#
# === Example
#
# ```shell
# augeas.aptconf --setting APT::Periodic::Update-Package-Lists --value 1 --file /etc/apt/apt.conf.d/20auto-upgrades
# augeas.aptconf --setting APT::Periodic::Unattended-Upgrade --value 1 --file /etc/apt/apt.conf.d/20auto-upgrades
# ```
#
function augeas.aptconf {
  waffles.subtitle "augeas.aptconf"

  if ! waffles.command_exists augtool ; then
    log.error "Cannot find augtool."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  waffles.options.create_option state   "present"
  waffles.options.create_option setting "__required__"
  waffles.options.create_option value   "__required__"
  waffles.options.create_option file    "__required__"
  waffles.options.parse_options "$@"

  # Local Variables
  #local _path=$(echo ${options[setting]} | sed -e 's/::/\//g')
  local _path=${options[setting]//::/\/}

  # Convert into an `augeas.generic` resource
  augeas.generic --name "augeas.aptconf.${options[setting]}" \
                 --lens Aptconf \
                 --file "${options[file]}" \
                 --command "set $_path[. = '${options[value]}'] '${options[value]}'"
}
