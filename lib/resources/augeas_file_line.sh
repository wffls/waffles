# == Name
#
# augeas.file_line
#
# === Description
#
# Manages single lines in a file
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: An arbitrary name for the line. Required. namevar.
# * line: The line to manage in the file. Required.
# * file: The file to add the line. Required. namevar.
#
# === Example
#
# ```shell
# augeas.file_line --name foo --file /root/foo.txt --line "Hello, World!"
# ```
#
function augeas.file_line {
  waffles.subtitle "augeas.file_line"

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
  waffles.options.create_option name  "__required__"
  waffles.options.create_option line  "__required__"
  waffles.options.create_option file  "__required__"
  waffles.options.parse_options "$@"

  # Convert to an `augeas.generic` resource
  augeas.generic --name "augeas.file_line.${options[name]}" \
                 --lens Simplelines \
                 --file "${options[file]}" \
                 --command "set 01 '${options[line]}'" \
                 --notif "*[. = '${options[line]}']"
}
