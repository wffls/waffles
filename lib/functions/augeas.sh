function augeas.run {
  waffles.options.create_option lens   "__required__"
  waffles.options.create_option file   "__required__"
  waffles.options.parse_options "$@"

  shift 4
  local _augeas_commands=("${@}")
  if [[ ${#_augeas_commands[@]} == 0 ]]; then
    log.error "No commands passed."
    return
  fi

  local _commands=$(IFS=$'\n'; echo "${_augeas_commands[*]}")
  local _result=$(cat <<EOF | augtool -A 2>&1 | grep -v Saved | grep -v rm
set /augeas/load/${options[lens]}/lens ${options[lens]}.lns
set /augeas/load/${options[lens]}/incl ${options[file]}
load
$_commands
save
EOF
)

  if [[ -n $_result ]]; then
    echo "error: $_result"
    return
  fi
}

function augeas.get {
  local -A options
  waffles.options.create_option lens "__required__"
  waffles.options.create_option file "__required__"
  waffles.options.create_option path "__required__"
  waffles.options.parse_options "$@"

  local _path=$(echo "${options[file]}/${options[path]}")

  local _result=$(cat <<EOF | augtool -A
set /augeas/load/${options[lens]}/lens ${options[lens]}.lns
set /augeas/load/${options[lens]}/incl ${options[file]}
load
match /files${_path}
EOF
)

  if [[ $_result =~ "no matches" ]]; then
    echo "absent"
    return
  fi

  echo "present"
}
