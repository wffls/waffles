#!/bin/bash

# Functions

# help prints a standard help message
function help {
  echo
  echo "waffleseed - Compiles a Role's Data and Profile into a deployable file."
  echo
  echo "Options:"
  echo "  -h: help"
  echo "  -d: debug"
  echo "  -o: output directory By default ."
  echo "  -r: role, stored in site/roles"
  echo
  echo "Usage:"
  echo "  waffleseed.sh -r <role>: compile the role into a waffleseed"
  echo
  exit 1
}

function compile_waffleseed {
  # Trick Waffles into thinking this is a remote run.
  # This way, it builds a list of files instead of executing them.
  WAFFLES_REMOTE=1

  # Read the role and compile the list of files that make up the role
  waffles.include $role_script

  # Make a temporary staging area
  local _tmp=$(mktemp -d ${WAFFLESEED_OUTPUT_DIR}/waffleseed-XXX)
  mkdir -p "$_tmp/waffles/site/"
  mkdir "$_tmp/waffles/site/data"
  mkdir "$_tmp/waffles/site/roles"
  mkdir "$_tmp/waffles/site/profiles"

  # Copy Waffles to the staging area
  cp -a $WAFFLES_DIR/lib $WAFFLES_DIR/waffles.sh $WAFFLES_DIR/waffles.conf $_tmp/waffles
  cp "${WAFFLES_SITE_DIR}/roles/${role}.sh" $_tmp/waffles/site/roles

  # Copy over the data and profiles files
  for i in "${!_waffles_remote_copy[@]}"; do
    string.split $i "/"
    cp -a "$WAFFLES_SITE_DIR/$i" "${_tmp}/waffles/site/${__split[0]}"
  done

  # Create a tarball of waffles and the role's files
  cd
  tar czvf "${WAFFLESEED_OUTPUT_DIR}/${role}.tar.gz" -C $_tmp .

  rm -rf "$_tmp"

  # Create a self-extrating and self-executing script
  cat > "${WAFFLESEED_OUTPUT_DIR}/${role}.ws" <<EOF
#!/bin/bash
SKIP=\$(awk '/^__TARFILE_FOLLOWS__/ { print NR + 1; exit 0; }' \$0)
THIS="\$0"
tail -n +\$SKIP \$THIS | tar -xz
WAFFLES_CONFIG_FILE=waffles/waffles.conf bash waffles/waffles.sh -r $role
rm -rf waffles
exit 0
__TARFILE_FOLLOWS__
EOF

  # Cat the tarfile to the self-executing script
  cat "${WAFFLESEED_OUTPUT_DIR}/${role}.tar.gz" >> "${WAFFLESEED_OUTPUT_DIR}/${role}.ws"

  # Delete the tarball
  rm "${WAFFLESEED_OUTPUT_DIR}/${role}.tar.gz"

  # Make the script executable
  chmod +x "${WAFFLESEED_OUTPUT_DIR}/${role}.ws"
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
  source "$WAFFLES_CONFIG_fILE"
fi

# Make sure WAFFLES_DIR has a value
if [[ -z $WAFFLES_DIR ]]; then
  echo "WAFFLES_DIR is not set."
  exit 1
fi

# Make sure WAFFLES_DIR has a value
if [[ -z $WAFFLES_SITE_DIR ]]; then
  echo "WAFFLES_DIR is not set."
  exit 1
fi

# Read in the Waffles functions and resources
source "$WAFFLES_DIR/lib/init.sh"

# Parse options
while getopts :hdo:r: opt; do
  case $opt in
    h)
      help
      exit 1
      ;;
    d)
      WAFFLES_DEBUG=1
      ;;
    o)
      WAFFLESEED_OUTPUT_DIR="$OPTARG"
      ;;
    r)
      role="$OPTARG"
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      help
      exit 1
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

if [[ -z $WAFFLESEED_OUTPUT_DIR ]]; then
  WAFFLESEED_OUTPUT_DIR="$(pwd)"
fi

role_script="${WAFFLES_SITE_DIR}/roles/${role}.sh"
if [[ ! -f $role_script ]]; then
  log.error "File ${role_script} does not exist for role ${role}."
  exit 1
fi

(compile_waffleseed)
