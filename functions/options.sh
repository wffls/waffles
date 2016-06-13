function waffles.options.create_option {
  if [[ -n $2 ]]; then
    if [[ $2 == "__required__" ]]; then
      options[$1/required]=1
    fi
    options[$1]="$2"
  else
    options[$1]=
  fi
}

function waffles.options.create_mv_option {
  if [[ -n $1 ]]; then
    waffles.options.create_option "$1" "$2"
    options[$1/mv]=1
  fi
}

function waffles.options.parse_options {
  while [ $# -gt 0 ]; do
    log.debug "option $1, value $2"
    if [[ $2 =~ ^-- ]]; then
      local _err_key=${2//--}
      if [[ ${options[$_err_key]+isset} ]]; then
        log.error "Invalid options were passed: $1, $2"
        return 1
      fi
    fi

    local _opt_key=${1//--}
    if [[ ${options[$_opt_key/mv]+isset} ]]; then
      array.push $_opt_key "$2"
      options[$_opt_key]="__set__"
    else
      options[$_opt_key]="$2"
    fi

    shift; shift
  done

  # Special case for --help
  if [[ ${options[help]+isset} ]]; then
    local _resource="${FUNCNAME[1]//./_}"
    while read -r line; do
      if [[ $line =~ ^= ]]; then
        echo -e "${waffles_log_color_bold}${line}${waffles_log_color_reset}"
      else
        echo "$line"
      fi
    done < <(sed -e '/^function/q' -r -e 's/^#\ ?//' "$WAFFLES_DIR/resources/${_resource}.sh" | grep -v ^function | grep -v ^\`)
    return 1
  fi

   for opt in "${!options[@]}"; do
    if [[ ${options[$opt/required]+isset} ]] && [[ ${options[$opt]} == "__required__" || -z ${options[$opt]} ]]; then
      log.error "Missing required option: $opt"
      return 1
    fi
  done
}
