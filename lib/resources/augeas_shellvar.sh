# == Name
#
# augeas.shellvar
#
# === Description
#
# Manages simple k=v settings in a file.
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * key: The key. Required. namevar.
# * value: A value for the key. Required.
# * file: The file to add the variable to. Required. namevar.
#
# === Example
#
# ```shell
# augeas.shellvar --key foo --value bar --file /root/vars
# ```
#
function augeas.shellvar {
  waffles.subtitle "augeas.shellvar"

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
  waffles.options.create_option state "present"
  waffles.options.create_option key   "__required__"
  waffles.options.create_option value "__required__"
  waffles.options.create_option file  "__required__"
  waffles.options.parse_options "$@"

  # Local Variables
  local _name="${options[file]}.${options[key]}"

  # Convert to an `augeas.generic` resource
  augeas.generic --name "augeas.shellvar.${_name}" \
                 --lens Shellvars \
                 --file "${options[file]}" \
                 --command "set ${options[key]}[. = '${options[value]}'] '${options[value]}'"
}
