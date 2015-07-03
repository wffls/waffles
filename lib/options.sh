function stdlib.options.create_option {
  if [[ -n "$2" ]]; then
    if [[ "$2" == __required__ ]]; then
      options[$1/required]=1
    fi
    options[$1]="$2"
  else
    options[$1]=
  fi
}

function stdlib.options.create_mv_option {
  if [[ -n "$1" ]]; then
    stdlib.options.create_option "$1" "$2"
    options[$1/mv]=1
  fi
}

function stdlib.options.parse_options {
  while [ $# -gt 0 ]; do
    stdlib.debug "option $1, value $2"
    if [[ "$2" =~ ^-- ]]; then
      stdlib.error "Invalid options were passed: $1, $2"
      exit 1
    fi

    local _opt_key=$(echo $1 | tr -d -)
    if [[ "${options[$_opt_key/mv]+isset}" ]]; then
      stdlib.array_push $_opt_key "$2"
      options[$_opt_key]="__set__"
    else
      options[$_opt_key]="$2"
    fi

    shift; shift
  done

  for opt in "${!options[@]}"; do
    if [[ "${options[$opt/required]+isset}" ]] && [[ "${options[$opt]}" == __required__ || -z "${options[$opt]}" ]]; then
      stdlib.error "Missing required option: $opt"
      exit 1
    fi
  done
}
