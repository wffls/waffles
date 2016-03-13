# == Name
#
# augeas.host
#
# === Description
#
# Manages hosts in /etc/hosts
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: The host. Required. namevar.
# * ip: The IP address of the host. Required.
# * aliases: A CSV list of host aliases. Optional
# * file: The hosts file. Default: /etc/hosts.
#
# === Example
#
# ```shell
# augeas.host --name example.com --ip 192.168.1.1 --aliases www,db
# ```
#
function augeas.host {
  waffles.subtitle "augeas.host"

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
  waffles.options.create_option name    "__required__"
  waffles.options.create_option ip      "__required__"
  waffles.options.create_option aliases ""
  waffles.options.create_option file    "/etc/hosts"
  waffles.options.parse_options "$@"

  # Convert to an `augeas.generic` resource
  augeas.generic --name "augeas.hosts.${options[name]}" \
                 --lens Hosts \
                 --file "${options[file]}" \
                 --command "set 01/ipaddr '${options[ip]}'" \
                 --command "set 01/canonical '${options[name]}'" \
                 --notif "*/canonical[. = '${options[name]}']"

  string.split "${options[aliases]}" ","
  for a in "${__split[@]}"; do
    augeas.generic --name "augeas.hosts.$a" \
                   --lens Hosts \
                   --file "${options[file]}" \
                   --command "set *[ipaddr = '${options[ip]}']/alias[0] '$a'" \
                   --notif "*[ipaddr = '${options[ip]}']/canonical[. = '${options[name]}']/../alias[. = '$a']"
  done
}
