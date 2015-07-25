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
  echo "  -t: run in test mode. exit 1 if changes were made"
  echo
  echo "  -s: (push) remote server to connect to through SSH"
  echo "  -u: (push) the remote user to connect as through SSH. Default: root"
  echo "  -y: (push) whether or not to use sudo remotely. Default: false"
  echo "  -z: (push) the remote directory to copy Waffles to. Default: /etc/waffles"
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
    if [[ $i =~ sh$ ]]; then
      _include="$_include --include=site/$i"
    else
      _include="$_include --include=site/$i/**"
    fi
  done

  local _args
  if [[ -n $WAFFLES_NOOP ]]; then
    _args="$_args -n"
  fi

  if [[ -n $WAFFLES_DEBUG ]]; then
    _args="$_args -d"
  fi

  # To deploy to explicit IPv6 addresses, use the bracket form ([fd00:abcd::1]) and let the following code take care of the rest.
  local _rsync_server
  local _ssh_server
  if [[ $server =~ [][] ]]; then
    server="${server/[/}"
    server="${server/]/}"
    _rsync_server="[$WAFFLES_SSH_USER@$server]"
    _ssh_server="$WAFFLES_SSH_USER@$server"
  else
    _rsync_server="$WAFFLES_SSH_USER@$server"
    _ssh_server="$WAFFLES_SSH_USER@$server"
  fi

  # Determine if "sudo" is required
  local _remote_rsync_path
  local _remote_ssh_command
  if [[ -n $WAFFLES_REMOTE_SUDO ]]; then
    _remote_rsync_path="sudo rsync"
    _remote_ssh_command="sudo bash waffles.sh"
  else
    _remote_rsync_path="rsync"
    _remote_ssh_command="bash waffles.sh"
  fi

  rsync -azv --rsync-path="$_remote_rsync_path" --include='**/' --include='waffles.sh' --include='waffles.conf' --include='lib/**' $_include --include="site/roles/${role}.sh" --exclude='*' --prune-empty-dirs $WAFFLES_DIR/ "$_rsync_server:$WAFFLES_REMOTE_DIR"
  ssh $_ssh_server "cd $WAFFLES_REMOTE_DIR && $_remote_ssh_command $_args -r $role"
}

# Main Script

# Try to find waffles.conf in either /etc/waffles or ~/.waffles
if [[ -f "/etc/waffles/waffles.conf" ]]; then
  source /etc/waffles/waffles.conf
fi

if [[ -f ~/.waffles/waffles.conf ]]; then
  source ~/.waffles/waffles.conf
fi

# If CONFIG_FILE or WAFFLES_CONFIG_FILE is set, prefer it
if [[ -n $CONFIG_FILE ]]; then
  source "$CONFIG_FILE"
fi

if [[ -n $WAFFLES_CONFIG_FILE ]]; then
  source "$WAFFLES_CONFIG_FILE"
fi

# Make sure WAFFLES_SITE_DIR has a value
if [[ -z $WAFFLES_SITE_DIR ]]; then
  echo "WAFFLES_SITE_DIR is not set."
  exit 1
fi

# Read in the standard library
source "$WAFFLES_DIR/lib/init.sh"

# Parse options
while getopts :dhnr:s:tu:z:y opt; do
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
    z)
      WAFFLES_REMOTE_DIR="$OPTARG"
      ;;
    y)
      WAFFLES_REMOTE_SUDO="true"
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
if [[ ! -f $role_script ]]; then
  stdlib.error "File $role_script does not exist for role $role."
  exit 1
fi

# Call either the local or remote apply_role function
if [[ -n $server ]]; then
  (apply_role_remotely)
else
  (apply_role_locally)
fi
