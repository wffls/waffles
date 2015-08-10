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
  stdlib.subtitle "augeas.aptconf"

  if ! stdlib.command_exists augtool ; then
    stdlib.error "Cannot find augtool."
    if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
      exit 1
    else
      return 1
    fi
  fi

  # Resource Options
  local -A options
  stdlib.options.create_option state   "present"
  stdlib.options.create_option setting "__required__"
  stdlib.options.create_option value   "__required__"
  stdlib.options.create_option file    "__required__"
  stdlib.options.parse_options "$@"

  # Local Variables
  #local _path=$(echo ${options[setting]} | sed -e 's/::/\//g')
  local _path=${options[setting]//::/\/}

  # Convert into an `augeas.generic` resource
  augeas.generic --name "augeas.aptconf.${options[setting]}" \
                 --lens Aptconf \
                 --file "${options[file]}" \
                 --command "set $_path[. = '${options[value]}'] '${options[value]}'"
}
