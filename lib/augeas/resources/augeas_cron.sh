# == Name
#
# augeas.cron
#
# === Description
#
# Manages a cron entry in /etc/cron.d/
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: An arbitrary name for the cron Required. namevar.
# * user: The user to run the cron under. Default: root.
# * minute: The minute to run the cron. Default: *.
# * hour: The hour to run the cron. Default: *.
# * dom: The day of month to run the cron. Default: *.
# * month: The month to run the cron. Default *.
# * dow: The day of the week to run the cron. Default *.
# * cmd: The command to run. Required.
#
# === Example
#
# ```shell
# augeas.cron --name metrics --minute "*/5" --cmd /usr/local/bin/collect_metrics.sh
# ```
#
function augeas.cron {
  stdlib.subtitle "augeas.cron"

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
  stdlib.options.create_option state  "present"
  stdlib.options.create_option name   "__required__"
  stdlib.options.create_option user   "root"
  stdlib.options.create_option minute "*"
  stdlib.options.create_option hour   "*"
  stdlib.options.create_option dom    "*"
  stdlib.options.create_option month  "*"
  stdlib.options.create_option dow    "*"
  stdlib.options.create_option cmd    "__required__"
  stdlib.options.parse_options "$@"

  # Local Variables
  local _file="/etc/cron.d/${options[name]}"

  # Convert into an `augeas.generic` resource
  augeas.generic --name "augeas.cron.${options[name]}" \
                 --lens Cron \
                 --file "$_file" \
                 --command "set entry[. = '${options[cmd]}'] '${options[cmd]}'" \
                 --command "set entry[. = '${options[cmd]}']/time/minute '${options[minute]}'" \
                 --command "set entry[. = '${options[cmd]}']/time/hour '${options[hour]}'" \
                 --command "set entry[. = '${options[cmd]}']/time/dayofmonth '${options[dom]}'" \
                 --command "set entry[. = '${options[cmd]}']/time/month '${options[month]}'" \
                 --command "set entry[. = '${options[cmd]}']/time/dayofweek '${options[dow]}'" \
                 --command "set entry[. = '${options[cmd]}']/user '${options[user]}'"
}
