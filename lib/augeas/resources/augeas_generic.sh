# == Name
#
# augeas.generic
#
# === Description
#
# Change a file using Augeas
#
# === Parameters
#
# * state: The state of the resource. Required. Default: present.
# * name: An arbitrary name for the resource. Required. namevar.
# * lens: The Augeas lens to use without the .lns extension. Required.
# * lens_path: A custom directory that contain lenses. Optional. Multi-var.
# * command: A single Augeas command to run. Optional. Multi-var.
# * onlyif: A match conditional to check prior to running commands. If `true`, the command(s) are run. Optional.
# * notif: The same as `onlyif` but when the match should fail. Optional.
# * file: The file to modify. Required. namevar.
#
# === onlyif / notif Conditional Tests
#
# `onlyif` and `notif` tests have the following format:
#
# ```shell
# --onlyif "<path> <function> <operator> <comparison>"
# ```
#
# ==== Size
#
# Size compares the amount of matches.
#
# * `size -lt 1`
# * `size -gt 1`
# * Any numerical comparisons
#
# ==== Path
#
# * Will compare the returned path(s) with a string:
#
# * `path not_include <string>`
# * `path include <string>`
# * `path is <string>`
# * `path is_not <string>`
#
# ==== Result
#
# Result will compare the returned result(s) with a string:
#
# * `result not_include <string>`
# * `result include <string>`
# * `result is <string>`
# * `result is_not <string>`
#
# ==== Conditional Test Examples
#
# Assume `/files/etc/hosts`:
#
# * `*/ipaddr[. =~ regexp("127.*")]`
# * `*/ipaddr[. =~ regexp("127.*")] size -lt 1`
# * `*/ipaddr[. =~ regexp("127.*")] size -gt 1`
# * `*/ipaddr[. =~ regexp("127.*")] path not_include 127.0.0.1`
# * `*/ipaddr[. = "127.0.0.1"]/../canonical result include localhost`
#
# === Example
#
# ```shell
# augeas.generic --name test --lens Hosts --file /root/hosts \
#   --command "set *[canonical = 'localhost'][1]/ipaddr '10.3.3.27'" \
#   --onlyif "*/ipaddr[. = '127.0.0.1']/../canonical result include 'localhost'"
#
# augeas.generic --name test2 --lens Hosts --file /root/hosts \
#   --command "set 0/ipaddr '8.8.8.8'" \
#   --command "set 0/canonical 'google.com'" \
#   --onlyif "*/ipaddr[. = '8.8.8.8'] result not_include '8.8.8.8'"
#
# augeas.generic --name test3 --lens Hosts --file /root/hosts \
#   --command "set 0/ipaddr '1.1.1.1'" \
#   --command "set 0/canonical 'foobar.com'" \
#   --onlyif "*/ipaddr[. = '1.1.1.1'] path not_include 'ipaddr'"
#
# augeas.generic --name test4 --lens Hosts --file /root/hosts \
#   --command "set 0/ipaddr '2.2.2.2'" \
#   --command "set 0/canonical 'barfoo.com'" \
#   --onlyif "*/ipaddr[. = '2.2.2.2'] size -eq 0"
#
# augeas.generic --name test5 --lens Hosts --file /root/hosts \
#   --command "set 0/ipaddr '3.3.3.3'" \
#   --command "set 0/canonical 'bazbar.com'" \
#   --onlyif "*/ipaddr[. = '3.3.3.3'] size -lt 1"
# ```
#
function augeas.generic {
  stdlib.subtitle "augeas.generic"

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
  local -a command
  local -a lens_path
  stdlib.options.create_option state        "present"
  stdlib.options.create_option name         "__required__"
  stdlib.options.create_option lens         "__required__"
  stdlib.options.create_mv_option command   "__required__"
  stdlib.options.create_option file         "__required__"
  stdlib.options.create_mv_option lens_path
  stdlib.options.create_option onlyif
  stdlib.options.create_option notif
  stdlib.options.parse_options "$@"

  # Local Variables
  local _name="${options[name]}"
  local _file="${options[file]}"
  local _file_path="/files$_file"
  local _lens="${options[lens]}"
  local -a _augeas_init=()

  # Internal Resource Configuration
  if [[ $(stdlib.array_length lens_path) -gt 0 ]]; then
    for lp in "${lens_path[@]}"; do
      _lens_path="-I $lp "
    done
  fi

  # Prep the augtool session
  _augeas_init+=("set /augeas/load/$_lens/lens ${_lens}.lns")
  _augeas_init+=("set /augeas/load/$_lens/incl $_file")
  _augeas_init+=("load")

  # Process the resource
  stdlib.resource.process "augeas.generic" "$_name"
}

function augeas.generic.read {
  local _test _return _return_expected _commands _pid _error _testpath
  local _path _function _operator _comparison _c
  local -a _result
  local -a _parts
  local -a _augeas_commands=( "${_augeas_init[@]}" )

  # If `onlyif` or `notif` was specified, check and see the result of the command.
  if [[ -n ${options[onlyif]} ]] || [[ -n ${options[notif]} ]]; then
    if [[ -n ${options[onlyif]} ]]; then
      _return_expected=0
      _parts=(${options[onlyif]})
    else
      _return_expected=1
      _parts=(${options[notif]})
    fi

    # Remove possible surrounding quotes
    _comparison="${_parts[-1]}"
    _comparison=$(echo $_comparison | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
    stdlib.array_pop _parts >/dev/null

    _operator="${_parts[-1]}"
    stdlib.array_pop _parts >/dev/null

    _function="${_parts[-1]}"
    stdlib.array_pop _parts >/dev/null

    _path=$(stdlib.array_join _parts " ")
    _path="${_file_path}/$_path"

    case "$_function" in
      size)
        _test="size"
        ;;
      path)
        _test="path_or_result"
        ;;
      result)
        _test="path_or_result"
        ;;
      *)
        _test="path_exists"
        if [[ -n ${options[onlyif]} ]]; then
          _path="${_file_path}/${options[onlyif]}"
        else
          _path="${_file_path}/${options[notif]}"
        fi
        ;;
    esac

    _augeas_commands+=("match $_path")
    _commands=$(IFS=$'\n'; echo "${_augeas_commands[*]}")
    _pid=$$
    mapfile -t _result < <(augtool $_lens_path -A 2>/tmp/augeas_error.$pid <<< "$_commands" | grep -v "no matches")

    if [[ -s "/tmp/augeas_error.$pid" ]]; then
      _error=$(</tmp/augeas_error.$pid)
    fi

    stdlib.debug_mute rm /tmp/augeas_error.pid

    if [[ -n $_error ]]; then
      stdlib.error "Augeas error: $_error"
      stdlib_current_state="error"
      return
    fi

    augeas.generic.test_${_test}
    _return=$?

    if [[ $_return == $_return_expected ]]; then
      stdlib_current_state="absent"
      return
    fi

  else
    # Run the set of commands and see if they were successful.
    for c in "${command[@]}"; do
      _c=($c)
      _c[1]="${_file_path}/${_c[1]}"
      c=$(stdlib.array_join _c " ")

      _augeas_commands+=("$c")
    done
    _augeas_commands+=("save")
    _augeas_commands+=("print /augeas/events/saved")

    _commands=$(IFS=$'\n'; echo "${_augeas_commands[*]}")
    _pid=$$
    _result=$(augtool $_lens_path -An 2>/tmp/augeas_error.$pid <<< "$_commands" | grep -v Saved)

    if [[ -s "/tmp/augeas_error.$pid" ]]; then
      _error=$(</tmp/augeas_error.$pid)
    fi

    if [[ -f "${_file}.augnew" ]]; then
      stdlib.debug_mute rm "${_file}.augnew"
    fi

    stdlib.debug_mute rm /tmp/augeas_error.pid

    if [[ -n $_error ]]; then
      stdlib.error "Augeas error: $_error"
      stdlib_current_state="error"
      return
    fi

    _return="/augeas/events/saved = \"$_file_path\""
    if [[ $_result == $_return  ]]; then
      stdlib_current_state="absent"
      return
    elif [[ $_result =~ ^error ]]; then
      stdlib.error "Error updating $_file."
      stdlib_current_state="error"
      return 1
    fi
  fi

  stdlib_current_state="present"
}

function augeas.generic.create {
  local _result _return _c _pid
  local -a _augeas_commands=( "${_augeas_init[@]}" )

  # Run the set of commands and see if they were successful.
  for c in "${command[@]}"; do
    _c=($c)
    _c[1]="${_file_path}/${_c[1]}"
    c=$(stdlib.array_join _c " ")

    _augeas_commands+=("$c")
  done
  _augeas_commands+=("save")
  _augeas_commands+=("print /augeas/events/saved")

  _commands=$(IFS=$'\n'; echo "${_augeas_commands[*]}")
  _result=$(augtool $_lens_path -A 2>/tmp/augeas_error.$pid <<< "$_commands" | grep -v Saved)

  if [[ -s "/tmp/augeas_error.$pid" ]]; then
    _error=$(</tmp/augeas_error.$pid)
  fi

  stdlib.debug_mute rm /tmp/augeas_error.pid

  if [[ -n $_error ]]; then
    stdlib.error "Augeas error: $_error"
    return
  fi

  _return="/augeas/events/saved = \"$_file_path\""
  if [[ $_result == $_return  ]]; then
    stdlib_current_state="absent"
    return
  elif [[ $_result =~ ^error ]]; then
    stdlib.error "Error updating $_file."
    return 1
  fi
}

function augeas.generic.update {
  augeas.generic.delete
  augeas.generic.create
}

function augeas.generic.delete {
  stdlib.warn "Unable to perform deletions on Augeas resources."
  return
}

function augeas.generic.test_size {
  local _line_count=$(stdlib.array_length _result)
  if [ $_line_count $_operator $_comparison ]; then
    return 0
  else
    return 1
  fi
}

function augeas.generic.test_path_or_result {
  local _match="false"
  local _part _c

  for r in "${_result[@]}"; do
    stdlib.split "$r" " = "
    if [[ $_function == "path" ]]; then
      _part="${__split[0]}"
    else
      _part="${__split[1]}"
    fi

    if [[ $_operator == "include" ]] || [[ $_operator == "not_include" ]]; then
      if [[ $_part =~ $_comparison ]]; then
        _match="true"
        break
      fi
    elif [[ $_operator == "is" ]] || [[ $_operator == "is_not" ]]; then
      if [[ $_part == $_comparison ]]; then
        _match="true"
        break
      fi
    fi
  done

  if [[ $_operator == "include" ]] || [[ $_operator == "is" ]]; then
    if [[ $_match == "true" ]]; then
      return 0
    else
      return 1
    fi
  elif [[ $_operator == "not_include" ]] || [[ $_operator == "is_not" ]]; then
    if [[ $_match == "true" ]]; then
      return 1
    else
      return 0
    fi
  fi
}

function augeas.generic.test_path_exists {
  local _match="false"

  if [[ $(stdlib.array_length _result) -gt 0 ]]; then
    return 0
  else
    return 1
  fi
}
