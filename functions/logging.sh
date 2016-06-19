# Colors and Styles
declare waffles_log_color_bold='\e[1m'
declare waffles_log_color_reset='\e[0m'

log.debug() {
  if waffles.debug ; then
    log._log debug "$@"
  fi
}

log.info() {
  log._log info "$@"
}

log.warn() {
  log._log warn "$@"
}

log.error() {
  log._log error "$@"
}

log._log() {
  local _log_level="$1"; shift

  if [[ -n $waffles_resource ]]; then
    _log_level=" ${_log_level}"
  fi

  echo "${waffles_resource}${_log_level}: ${@}" >&2
}
