# == Name
#
# augeas.ssh_authorized_key
#
# === Description
#
# Manages ssh_authorized_keys
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The ssh_authorized_key. Required. namevar.
# * key: The ssh key. Required.
# * type: The key type. Required.
# * key_options: A CSV list of ssh_authorized_key options. Optional
# * file: The ssh_authorized_keys file. Required.
#
# === Example
#
# ```shell
# augeas.ssh_authorized_key --name jdoe --key "AAAAB3NzaC1..." --type ssh-rsa --comment "jdoe@laptop" --file "/root/.ssh/authorized_keys"
# ```
#
# === Notes
#
# TODO: `options` have not been tested.
#
function augeas.ssh_authorized_key {
  waffles.subtitle "augeas.ssh_authorized_key"

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
  local -a key_options
  waffles.options.create_option state          "present"
  waffles.options.create_option name           "__required__"
  waffles.options.create_option key            "__required__"
  waffles.options.create_option type           "__required__"
  waffles.options.create_option file           "__required__"
  waffles.options.create_mv_option key_options
  waffles.options.parse_options "$@"

  # Local variables
  local -a _commands

  # Internal Resource Configuration
  for ko in "${key_options[@]}"; do
    _commands+=("--command")
    _commands+=("set key[. = '${options[key]}']/option[. = '$ko'] '$ko'")
  done

  # Convert to an `augeas.generic` resource
  augeas.generic --name "augeas.ssh_authorized_key.${options[name]}" \
                 --lens Authorized_Keys \
                 --file "${options[file]}" \
                 --command "set key[. = '${options[key]}'] '${options[key]}'" \
                 --command "set key[. = '${options[key]}']/type '${options[type]}'" \
                 --command "set key[. = '${options[key]}']/comment '${options[comment]}'" \
                 "${_commands[@]}"
}
