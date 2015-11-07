# == Name
#
# stdlib.cron
#
# === Description
#
# Manages cron entries
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: A single-word name for the cron. Required. namevar.
# * user: The user to run the cron job as. Default: root.
# * cmd: The command to run. Required.
# * minute: The minute field of the cron. Default: *.
# * hour: The hour field of the cron. Default: *.
# * dom: The day of month field for the cron. Default: *.
# * month: The month field of the cron. Default: *.
# * dow: The day of week field of the cron. Default: *.
#
# === Example
#
# ```shell
# stdlib.cron --name foobar --cmd /path/to/some/report --minute "*/5"
# ```
#
# === TODO
#
# Add support for prefix info such as PATH, MAILTO.
#
function stdlib.cron {
  stdlib.subtitle "stdlib.cron"

  # Resource Options
  local -A options
  stdlib.options.create_option state  "present"
  stdlib.options.create_option name   "__required__"
  stdlib.options.create_option user   "root"
  stdlib.options.create_option cmd    "__required__"
  stdlib.options.create_option minute "*"
  stdlib.options.create_option hour   "*"
  stdlib.options.create_option dom    "*"
  stdlib.options.create_option month  "*"
  stdlib.options.create_option dow    "*"
  stdlib.options.parse_options "$@"

  # Local Variables
  local entry="${options[minute]} ${options[hour]} ${options[dom]} ${options[month]} ${options[dow]} ${options[cmd]} # ${options[name]}"
  local _entry

  # Process the resource
  stdlib.resource.process "stdlib.cron" "$entry"
}

function stdlib.cron.read {
  _entry=$(crontab -u "${options[user]}" -l 2> /dev/null | grep "# ${options[name]}$")
  if [[ -z $_entry ]]; then
    stdlib_current_state="absent"
    return
  fi

  if [[ $entry != $_entry ]]; then
    stdlib_current_state="update"
    return
  fi

  stdlib_current_state="present"
}

function stdlib.cron.create {
  local _script
  read -r -d '' _script<<EOF
(
  crontab -u "${options[user]}" -l 2> /dev/null | grep -v "# ${options[name]}$" 2> /dev/null || true
  echo "$entry"
) | crontab -u "${options[user]}" -
EOF
  stdlib.capture_error "$_script"
}

function stdlib.cron.update {
  stdlib.cron.create
}

function stdlib.cron.delete {
  local _script
  read -r -d '' _script<<EOF
(
  crontab -u "${options[user]}" -l 2> /dev/null | grep -v "# ${options[name]}$" 2> /dev/null || true
) | crontab -u "${options[user]}" -
EOF
  stdlib.capture_error "$_script"
}
