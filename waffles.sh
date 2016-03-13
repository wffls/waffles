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
  echo "  -p: color (pretty) output"
  echo "  -r: role, stored in site/roles"
  echo "  -t: run in test mode. exit 1 if changes were made"
  echo
  echo "  -c: (push) the number of times to retry connecting. Default: 5"
  echo "  -k: (push) the ssh key to use. Default: ~/.ssh/id_rsa"
  echo "  -s: (push) remote server to connect to through SSH"
  echo "  -u: (push) the remote user to connect as through SSH. Default: root"
  echo "  -w: (push) the amount of time in seconds to wait between retrying. Default: 5"
  echo "  -y: (push) whether or not to use sudo remotely. Default: false"
  echo "  -z: (push) the remote directory to copy Waffles to. Default: ~/.waffles"
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
  if [[ -z $WAFFLES_REMOTE_SSH_KEY ]] || [[ ! -f $WAFFLES_REMOTE_SSH_KEY ]]; then
    stdlib.error "SSH key not specified or not found."
    exit 1
  fi

  stdlib.include $role_script

  local _include
  for i in "${!_stdlib_remote_copy[@]}"; do
    if [[ $i =~ sh$ ]]; then
      _include="$_include --include=$i"
    else
      _include="$_include --include=$i/**"
    fi
  done

  local _git_include
  for i in "${!_stdlib_remote_gitcache_copy[@]}"; do
    _git_include="$_git_include --include=$i/**"
  done

  local _args
  local _rsync_quiet="-q"
  if [[ -n $WAFFLES_NOOP ]]; then
    _args="$_args -n"
  fi

  if [[ -n $WAFFLES_DEBUG ]]; then
    _args="$_args -d"
    _rsync_quiet=""
  fi

  # To deploy to explicit IPv6 addresses, use the bracket form ([fd00:abcd::1])
  # and let the following code take care of the rest.
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

  stdlib.debug "Testing connectivity to $_ssh_server"
  _ssh_status=255
  _attempt=0
  while [[ $_ssh_status -ne 0 && $_attempt -lt $WAFFLES_REMOTE_SSH_ATTEMPTS ]]; do
    _attempt=$(( _attempt+1 ))
    stdlib.debug "Attempt $_attempt of $WAFFLES_REMOTE_SSH_ATTEMPTS."
    stdlib.debug_mute ssh -i $WAFFLES_REMOTE_SSH_KEY $_ssh_server pwd
    _ssh_status=$?
    if [[ $_ssh_status -ne 0 ]]; then
      if [[ $_attempt -lt $WAFFLES_REMOTE_SSH_ATTEMPTS ]]; then
        stdlib.debug "Unable to connect. Waiting $WAFFLES_REMOTE_SSH_WAIT seconds."
        sleep $WAFFLES_REMOTE_SSH_WAIT
      fi
    fi
  done

  if [[ $_ssh_status != 0 ]]; then
    stdlib.error "Unable to connect to $_ssh_server. Exiting."
    exit 1
  fi

  stdlib.debug "Copying Waffles to remote server $_rsync_server"
  rsync -azv $_rsync_quiet -e "ssh -i $WAFFLES_REMOTE_SSH_KEY" --rsync-path="$_remote_rsync_path" --include='**/' --include='waffles.sh' --include='waffles.conf' --include='lib/**' --exclude='*' --prune-empty-dirs $WAFFLES_DIR/ "$_rsync_server:$WAFFLES_REMOTE_DIR"

  stdlib.debug "Copying site to remote server $_rsync_server"
  rsync -azv $_rsync_quiet -e "ssh -i $WAFFLES_REMOTE_SSH_KEY" --rsync-path="$_remote_rsync_path" --include="**/" $_include --include="roles/${role}.sh" --exclude='*' --prune-empty-dirs $WAFFLES_SITE_DIR/ "$_rsync_server:$WAFFLES_REMOTE_DIR/site/"

  if [[ -n $_git_include ]]; then
    stdlib.debug "Copying git profiles to remote server $_rsync_server"
    rsync -azv $_rsync_quiet -e "ssh -i $WAFFLES_REMOTE_SSH_KEY" --rsync-path="$_remote_rsync_path" --include="**/" $_git_include --exclude='*' --prune-empty-dirs $WAFFLES_SITE_DIR/.gitcache/roles/$role/profiles/ "$_rsync_server:$WAFFLES_REMOTE_DIR/site/profiles/"
  fi

  ssh -i $WAFFLES_REMOTE_SSH_KEY $_ssh_server "cd $WAFFLES_REMOTE_DIR && $_remote_ssh_command $_args -r $role"
}

function apply_wafflescript {
  stdlib.debug "Running wafflescript"
  source "${1:-/dev/stdin}"
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

# Determine if this is a wafflescript
_my_name=$(basename $0)
if [[ $_my_name == "wafflescript" ]]; then
  (apply_wafflescript $1)
  exit 0
fi

# Parse options
while getopts :c:dhk:npr:s:tu:w:yz: opt; do
  case $opt in
    c)
      WAFFLES_REMOTE_SSH_ATTEMPTS="$OPTARG"
      ;;
    d)
      WAFFLES_DEBUG=1
      ;;
    h)
      help
      exit 1
      ;;
    k)
      WAFFLES_REMOTE_SSH_KEY="$OPTARG"
      ;;
    n)
      WAFFLES_NOOP=1
      ;;
    p)
      WAFFLES_COLOR_OUTPUT=1
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
    w)
      WAFFLES_REMOTE_SSH_WAIT="$OPTARG"
      ;;
    y)
      WAFFLES_REMOTE_SUDO="true"
      ;;
    z)
      WAFFLES_REMOTE_DIR="$OPTARG"
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
