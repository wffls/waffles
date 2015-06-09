#!/usr/bin/env bash

# Functions

# help prints a standard help message
function help {
  echo
  echo "waffles - A simple configuration management and deployment tool."
  echo
  echo "Options:"
  echo "  -h: help"
  echo "  -d: debug"
  echo "  -n: noop"
  echo "  -r: role, stored in site/roles"
  echo "  -s: remote server to connect to through SSH"
  echo "  -t: run in test mode. exit 1 if changes were made"
  echo "  -u: the remote user to connect as through SSH"
  echo
  echo "Usage:"
  echo "  waffles.sh -r <role>: apply a role to the local server"
  echo "  waffles.sh -s www.example.com -u root -r web: apply the web role remotely to www.example.com as root"
  echo "  waffles.sh -d -r web: apply the web role locally in debug mode"
  echo "  waffles.sh -n -r web: apply the web role locally in no-op mode"
  echo "  waffles.sh -t -r web: apply the web role locally in test mode"
  echo
  exit 1
}

# apply_role_locally applies the role to the local node
function apply_role_locally {
  stdlib.include $role_script

  # If WAFFLES_TEST is set, exit 1 if any changes where made
  if [[ -n $WAFFLES_TEST ]]; then
    [[ $stdlib_resource_changes -eq 0 ]] || exit 1
  fi
}

# apply_role_remotely applies the role to a remote node
function apply_role_remotely {
  stdlib.include $role_script

  local _include
  for i in "${!stdlib_remote_copy[@]}"; do
    _include="$_include $WAFFLES_DIR/site/$i"
  done

  local _args
  if [[ -n $WAFFLES_NOOP ]]; then
    _args="$_args -n"
  fi

  if [[ -n $WAFFLES_DEBUG ]]; then
    _args="$_args -d"
  fi

  rsync -azvR $WAFFLES_DIR/waffles.* "$WAFFLES_DIR/lib" "$WAFFLES_DIR/site/roles/${role}.sh" $_include "$WAFFLES_SSH_USER@$server":/
  ssh "$WAFFLES_SSH_USER@$server" "cd $WAFFLES_DIR && bash waffles.sh $_args -r $role"
}

# Main Script

# Try to find waffles.conf in either /etc/waffles or ~/.waffles
if [[ -f /etc/waffles/waffles.conf ]]; then
  source /etc/waffles/waffles.conf
fi

if [[ -f ~/.waffles/waffles.conf ]]; then
  source ~/.waffles/waffles.conf
fi

# If CONFIG_FILE or WAFFLES_CONFIG_FILE is set, prefer it
if [[ -n "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [[ -n "$WAFFLES_CONFIG_FILE" ]]; then
  source "$WAFFLES_CONFIG_FILE"
fi

# Make sure WAFFLES_SITE_DIR has a value
if [[ -z "$WAFFLES_SITE_DIR" ]]; then
  echo "WAFFLES_SITE_DIR is not set."
  exit 1
fi

# Read in the standard library
source "$WAFFLES_DIR/lib/init.sh"

# Parse options
while getopts :dhnr:s:tu: opt; do
  case $opt in
    d)
      WAFFLES_DEBUG=1
      ;;
    h)
      help
      exit 1
      ;;
    n)
      WAFFLES_NOOP=1
      ;;
    r)
      role="$OPTARG"
      ;;
    s)
      WAFFLES_REMOTE=1
      server="$OPTARG"
      ;;
    t)
      WAFFLES_TEST=1
      ;;
    u)
      WAFFLES_SSH_USER="$OPTARG"
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      help
      exit 1;
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      help
      exit 1
      ;;
  esac
done

if [[ -z $role ]]; then
  help
  exit 1
fi

# Make sure the role is defined in a script.
role_script="${WAFFLES_SITE_DIR}/roles/${role}.sh"
if [[ ! -f "$role_script" ]]; then
  stdlib.error "File $role_script does not exist for role $role."
  exit 1
fi

# Call either the local or remote apply_role function
if [[ -n $server ]]; then
  (apply_role_remotely)
else
  (apply_role_locally)
fi
