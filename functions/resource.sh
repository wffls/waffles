# waffles_resource holds the current resource being processed.
declare -g waffles_resource=""

# waffles_resource_current_state holds the state of the last run resource
declare -g waffles_resource_current_state

# waffles_resource_changed returns true if the state of the last run resource
# changed. This resets every time a new resource is declared.
declare -g waffles_resource_changed

# waffles_total_changes keeps track of how many resources have been changed.
declare -g waffles_total_changes=0

waffles.resource.check_dependencies() {
  while [[ $# -gt 0 ]]; do
    if ! waffles.command_exists $1 ; then
      log.error "resource dependency not installed: $1"
      return 1
    fi

    shift
  done
}

waffles.resource.process() {
  if [[ $# -eq 2 ]]; then
    local _resource_type="$1"
    local _resource_name="$2"

    # Read the resource's state
    waffles.resource.read

    # Determine action based on state
    if [[ "$waffles_resource_current_state" == "error" ]]; then
      return 1
    fi

    if [[ "${options[state]}" == "absent" ]] || [[ "${options[state]}" == "stopped" ]]; then
      if [[ "$waffles_resource_current_state" != "absent" ]] && [[ "$waffles_resource_current_state" != "stopped" ]]; then
        log.info "$_resource_name state: $waffles_resource_current_state, should be ${options[state]}"
        waffles.resource.delete
      fi
    else
      case "$waffles_resource_current_state" in
        absent)
          log.info "$_resource_name state: absent, should be installed."
          waffles.resource.create
          ;;
        stopped)
          log.info "$_resource_name state: stopped, should be running."
          waffles.resource.create
          ;;
        present)
          log.debug "$_resource_name state: present."
          ;;
        running)
          log.debug "$_resource_name state: running."
          ;;
        update)
          log.info "$_resource_name state: out of date."
          waffles.resource.update
          ;;
        *)
          "${_resource_type}.${waffles_resource_current_state}"
          ;;
      esac
    fi

    # unset the resource
    waffles_resource=
  fi
}

waffles.resource.read() {
  waffles_resource_current_state=
  waffles_resource_changed=
  "${_resource_type}.read"
}

waffles.resource.create() {
  "${_resource_type}.create"
  waffles_resource_changed="true"
  waffles_total_changes=$(( $waffles_total_changes+1 ))
}

waffles.resource.update() {
  "${_resource_type}.update"
  waffles_resource_changed="true"
  waffles_total_changes=$(( $waffles_total_changes+1 ))
}

waffles.resource.delete() {
  "${_resource_type}.delete"
  waffles_resource_changed="true"
  waffles_total_changes=$(( $waffles_total_changes+1 ))
}
