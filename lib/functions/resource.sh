# waffles_resource_current_state holds the state of the last run resource
declare -g waffles_resource_current_state

# waffles_state_changed returns true if the state of any resource in a script
# or profile was changed.
declare -g waffles_state_changed

# waffles_resource_changed returns true if the state of the last run resource
# changed. This resets every time a new resource is declared.
declare -g waffles_resource_changed

function waffles.resource.process {
  if [[ $# -eq 2 ]]; then
    local _resource_type="$1"
    local _resource_name="$2"

    # Add the resource to the catalog
    waffles.catalog.add "$_resource_type/$_resource_name"

    # Read the resource's state
    waffles.resource.read

    # Determine action based on state
    if [[ "$waffles_resource_current_state" == "error" ]]; then
      if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
        exit 1
      else
        return 1
      fi
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
  fi
}

function waffles.resource.read {
  waffles_resource_current_state=""
  "${_resource_type}.read"
}

function waffles.resource.create {
  "${_resource_type}.create"
  waffles_state_changed="true"
  waffles_resource_changed="true"
  waffles_catalog_changes=$(( waffles_catalog_changes+1 ))
}

function waffles.resource.update {
  "${_resource_type}.update"
  waffles_state_changed="true"
  waffles_resource_changed="true"
  waffles_catalog_changes=$(( waffles_catalog_changes+1 ))
}

function waffles.resource.delete {
  "${_resource_type}.delete"
  waffles_state_changed="true"
  waffles_resource_changed="true"
  waffles_catalog_changes=$(( waffles_catalog_changes+1 ))
}
