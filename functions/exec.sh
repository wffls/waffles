# exec.mute turns off command output.
# If run in DEBUG, the command being executed will be logged.
function exec.mute {
  if waffles.noop ; then
    log.info "(noop) $@"
  else
    log.debug "Running \"$@\""
    eval $@ &>/dev/null
    return $?
  fi
}

# exec.capture_error will report back anything on fd 2.
# unfortunately a lot of noise usually ends up on fd 2,
# so this could be a little buggy.
function exec.capture_error {
  if waffles.noop ; then
    log.info "(noop) $@"
  else
    local _err
    log.info "Running \"$@\""
    _err=$(eval "$@" 2>&1 >/dev/null)
    if [[ $? != 0 ]]; then
      log.error "Errors occurred:"
      log.error "$_err"
      return $?
    else
      return 0
    fi
  fi
}

# exec.sudo runs a command as another user via sudo
# $1 = user
# $@ = command
function exec.sudo {
  if [[ $# -gt 1 ]]; then
    local _user
    array.shift "$@" _user
    exec.capture_error sudo -u "$_user" "$@"
  fi
}
