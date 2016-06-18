function log.debug {
  if waffles.debug ; then
    log._log debug "$@"
  fi
}

function log.info {
  log._log info "$@"
}

function log.warn {
  log._log warn "$@"
}

function log.error {
  log._log error "$@"
}

function log._log {
  local _log_level="$1"
  shift

  if [[ -n $waffles_resource ]]; then
    waffles_resource="${waffles_resource} "
  fi

  echo "${waffles_resource}${_log_level}: ${@}" >&2
}
