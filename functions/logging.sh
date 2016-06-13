# Colors
declare waffles_log_color_blue='\e[0;34m'
declare waffles_log_color_green='\e[1;32m'
declare waffles_log_color_red='\e[0;31m'
declare waffles_log_color_yellow='\e[1;33m'
declare waffles_log_color_bold='\e[1m'
declare waffles_log_color_reset='\e[0m'

function waffles.color {
  [[ -n $WAFFLES_COLOR_OUTPUT ]]
}

function log.debug {
  if waffles.debug ; then
    if waffles.color ; then
      echo -e "${waffles_log_color_blue}$(date +%H:%M:%S) (debug) ${waffles_title}${waffles_subtitle}${waffles_log_color_reset}${@}" >&2
    else
      echo -e "$(date +%H:%M:%S) (debug) ${waffles_title}${waffles_subtitle}${@}" >&2
    fi
  fi
}

function log.info {
  if waffles.color ; then
    echo -e "${waffles_log_color_green}$(date +%H:%M:%S) (info)  ${waffles_title}${waffles_subtitle}${waffles_log_color_reset}${@}" >&2
  else
    echo -e "$(date +%H:%M:%S) (info)  ${waffles_title}${waffles_subtitle}${@}" >&2
  fi
}

function log.warn {
  if waffles.color ; then
    echo -e "${waffles_log_color_yellow}$(date +%H:%M:%S) (warn)  ${waffles_title}${waffles_subtitle}${waffles_log_color_reset}${@}" >&2
  else
    echo -e "$(date +%H:%M:%S) (warn)  ${waffles_title}${waffles_subtitle}${@}" >&2
  fi
}

function log.error {
  if waffles.color ; then
    echo -e "${waffles_log_color_red}$(date +%H:%M:%S) (error) ${waffles_title}${waffles_subtitle}${waffles_log_color_reset}${@}" >&2
  else
    echo -e "$(date +%H:%M:%S) (error) ${waffles_title}${waffles_subtitle}${@}" >&2
  fi
}
