function stdlib.render_template {
  local -A options
  stdlib.options.create_option template    "__required__"
  stdlib.options.create_option variables   "__required__"
  stdlib.options.parse_options "$@"

  local -n _variables="${options[variables]}"

  _template=$(<"${options[template]}")

  for _key in "${!_variables[@]}"; do
    _value="${_variables[$_key]}"
    _template="${_template//\{\{ $_key \}\}/$_value}"
  done

  echo "$_template"
}
