#!/bin/bash
source /opt/waffles/init.sh

# Resource Options
declare -A options
waffles.options.create_option resource "__required__"
waffles.options.create_option platform
waffles.options.parse_options "$@"
if [[ $? != 0 ]]; then
  exit $?
fi

if [[ ${options[resource]} == "all" ]]; then
  for _r in test/resources/*.sh; do
    WAFFLES_RESOURCE="$_r" kitchen test ${options[platform]}
  done

else
  declare _resource_test=$(echo "${options[resource]}_test.sh" | sed -e 's/\./_/')
  if [[ ! -f test/resources/$_resource_test ]]; then
    log.error "Resource ${options[resource]} not found."
    exit 1
  else
    WAFFLES_RESOURCE="${options[resource]}" kitchen test ${options[platform]}
  fi
fi
