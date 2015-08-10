# == Name
#
# augeas.ini
#
# === Description
#
# Manages ini file entries
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * section: The section in the ini file. Required. namevar.
# * option: The option in the ini file. Required. namevar.
# * value: The value of the option. Required.
# * file: The file to add the variable to. Required. namevar.
#
# === Example
#
# ```shell
# augeas.ini --section DEFAULT --option foo --value bar --file /root/vars
# ```
#
function augeas.ini {
  stdlib.subtitle "augeas.ini"

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
  stdlib.options.create_option section "__required__"
  stdlib.options.create_option option  "__required__"
  stdlib.options.create_option value   "__required__"
  stdlib.options.create_option file    "__required__"
  stdlib.options.parse_options "$@"

  # Local Variables
  local _name="${options[file]}.${options[section]}.${options[option]}"

  # Create an `augeas.generic` resource
  augeas.generic --name "augeas.ini.$_name" \
                 --lens Puppet \
                 --file "${options[file]}" \
                 --command "set ${options[section]}/${options[option]} '${options[value]}'" \
                 --notif "${options[section]}/${options[option]}[. = '${options[value]}']"
}
