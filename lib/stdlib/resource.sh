function stdlib.resource.process {
  if [[ $# -eq 2 ]]; then
    local _resource_type="$1"
    local _resource_name="$2"

    # Add the resource to the catalog
    stdlib.catalog.add "$_resource_type/$_resource_name"

    # Read the resource's state
    stdlib.resource.read

    # Determine action based on state
    if [[ "$stdlib_current_state" == "error" ]]; then
      if [[ -n "$WAFFLES_EXIT_ON_ERROR" ]]; then
        exit 1
      else
        return 1
      fi
    fi

    if [[ "${options[state]}" == "absent" ]] || [[ "${options[state]}" == "stopped" ]]; then
      if [[ "$stdlib_current_state" != "absent" ]] && [[ "$stdlib_current_state" != "stopped" ]]; then
        stdlib.info "$_resource_name state: $stdlib_current_state, should be ${options[state]}"
        stdlib.resource.delete
      fi
    else
      case "$stdlib_current_state" in
        absent)
          stdlib.info "$_resource_name state: absent, should be installed."
          stdlib.resource.create
          ;;
        stopped)
          stdlib.info "$_resource_name state: stopped, should be running."
          stdlib.resource.create
          ;;
        present)
          stdlib.debug "$_resource_name state: present."
          ;;
        running)
          stdlib.debug "$_resource_name state: running."
          ;;
        update)
          stdlib.info "$_resource_name state: out of date."
          stdlib.resource.update
          ;;
        *)
          "${_resource_type}.${stdlib_current_state}"
          ;;
      esac
    fi
  fi

  stdlib.title
  stdlib.subtitle
}

function stdlib.resource.read {
  stdlib_current_state=""
  "${_resource_type}.read"
}

function stdlib.resource.create {
  "${_resource_type}.create"
  stdlib_state_change="true"
  stdlib_resource_change="true"
  stdlib_resource_changes=$(( stdlib_resource_changes+1 ))
}

function stdlib.resource.update {
  "${_resource_type}.update"
  stdlib_state_change="true"
  stdlib_resource_change="true"
  stdlib_resource_changes=$(( stdlib_resource_changes+1 ))
}

function stdlib.resource.delete {
  "${_resource_type}.delete"
  stdlib_state_change="true"
  stdlib_resource_change="true"
  stdlib_resource_changes=$(( stdlib_resource_changes+1 ))
}
