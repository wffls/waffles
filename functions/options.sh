# waffles.options.create_option creates a standard option to declare.
# If the value is __require__, Waffles will throw an error if the user did not
# specify a value.
waffles.options.create_option() {
  if [[ -n $2 ]]; then
    if [[ $2 == "__required__" ]]; then
      options[$1/required]=1
    fi
    options[$1]="$2"
  else
    options[$1]=
  fi
}

# waffles.options.create_mv_option declares a "multi-value" option. The user is
# able to specify this option more than once. Fictional example:
# mail.alias --name root --destination john --destination jane
waffles.options.create_mv_option() {
  if [[ -n $1 ]]; then
    waffles.options.create_option "$1" "$2"
    options[$1/mv]=1
  fi
}

# waffles.options.create_bool_option declares a boolean option. The user can
# only specify "true" or "false" for the value.
waffles.options.create_bool_option() {
  if [[ $# -ne 2 ]]; then
    log.error "Boolean options must have a default value. $1 is missing one."
    return 1
  fi

  waffles.options.create_option "$1" "$2"
  options[$1/bool]=1
}

# waffles.options.parse_options parses the options that a use specified.
# Options and values are parsed as pairs, read in as $1 and $2.
#
# If $2 is found to start with "--" it is considered an error since the most
# likely case is the user forgetting to specify a value. For example:
# mail.alias --name root --destination --destination jane
#
# If the option is a boolean option, an error will be thrown if the value is
# not true or false.
#
# If the option is a multi-value option, options are added to an array named
# after the option. For example:
# mail.alias --name root --destination john --destination jane
# $destination will be an array that contains john and jane.
# $destination must be pre-declared. See consul_service for a full example.
#
# If --help is given, read in the resource source code, parse it, and print the
# header documentation. This is disabled if WAFFLES_NO_HELP is set since it can
# be tricky to read in Waffles source scripts in temporary directories.
waffles.options.parse_options() {
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

    if [[ ${options[$_opt_key/bool]+isset} ]]; then
      if [[ $2 != "true" && $2 != "false" ]]; then
        log.error "$_opt_key must be true or false"
        return 1
      fi
    fi

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
    if [[ -z $WAFFLES_NO_HELP ]]; then
      local _resource="${FUNCNAME[1]//./_}"
      while read -r line; do
        if [[ $line =~ ^= ]]; then
          echo -e "${waffles_log_color_bold}${line}${waffles_log_color_reset}"
        else
          echo "$line"
        fi
      done < <(sed -e '/() {$/q' -r -e 's/^#\ ?//' "$WAFFLES_DIR/resources/${_resource}.sh" | grep -v "\(\) {$" | grep -v ^\`)
    fi
    return 1
  fi

  for opt in "${!options[@]}"; do
    if [[ ${options[$opt/required]+isset} ]] && [[ ${options[$opt]} == "__required__" || -z ${options[$opt]} ]]; then
      log.error "Missing required option: $opt"
      return 1
    fi
  done
}
