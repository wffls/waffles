#!/bin/bash
set -eu
source /root/.waffles/init.sh
source /etc/lsb-release

WAFFLES_DEBUG=1

if [[ -z ${BUSSER_ROOT:-} ]]; then
  log.info "apt-get update"
  exec.mute apt-get update
  exit 0
fi

declare _setup_failure=""
declare _teardown_failure=""
declare _test_failure=""
declare -a _create_failures=()
declare -a _post_create_failures=()
declare -a _update_failures=()
declare -a _post_update_failures=()
declare -a _delete_failures=()
declare -a _post_delete_failures=()

for t in /root/.waffles/resources/tests/*.sh; do
  declare _failure_happened=""
  declare _return_code=0
  source $t

  _resource=$(basename $t | sed -e 's/_test.sh//g' -e 's/_/./g')

  log.info "Running CRUD tests for $_resource"

  log.info "Running setup"
  "${_resource}.test.setup" || {
    log.error "Unable to setup tests for $_resource. Cannot proceed."
    _setup_failure=$_resource
    break
  }

  if [[ -z $_failure_happened ]]; then
    log.info "Running create tests"
    "${_resource}.test.create" || _return_code=$?
    if [[ $_return_code != 0 ]]; then
      array.push _create_failures $_resource
      _failure_happened=1
    fi

    _create_changes=$waffles_total_changes
  fi

  if [[ -z $_failure_happened ]]; then
    log.info "Verifying resources were successfully created"
    "${_resource}.test.create" || _return_code=$?
    if [[ $_return_code != 0 ]]; then
      array.push _post_create_failures $_resource
      _failure_happened=1
    fi

    _post_create_changes=$waffles_total_changes

    if [[ $_post_create_changes -gt $_create_changes ]]; then
      log.error "Changes happened on the system"
      array.push _post_create_failures $_resource
      _failure_happened=1
    fi
  fi

  if [[ -z $_failure_happened ]]; then
    log.info "Running update tests"
    "${_resource}.test.update" || _return_code=$?
    if [[ $_return_code != 0 ]]; then
      array.push _update_failures $_resource
      _failure_happened=1
    fi

    _update_changes=$waffles_total_changes
  fi

  if [[ -z $_failure_happened ]]; then
    log.info "Verifying resources were successfully updated"
    "${_resource}.test.update" || _return_code=$?
    if [[ $_return_code != 0 ]]; then
      array.push _post_update_failures $_resource
      _failure_happened=1
    fi

    _post_update_changes=$waffles_total_changes

    if [[ $_post_update_changes -gt $_update_changes ]]; then
      log.error "Changes happened on the system"
      array.push _post_update_failures $_resource
      _failure_happened=1
    fi
  fi

  if [[ -z $_failure_happened ]]; then
    log.info "Running delete tests"
    "${_resource}.test.delete" || _return_code=$?
    if [[ $_return_code != 0 ]]; then
      array.push _delete_failures $_resource
      _failure_happened=1
    fi

    _delete_changes=$waffles_total_changes
  fi

  if [[ -z $_failure_happened ]]; then
    log.info "Verifying resources were successfully deleted"
    "${_resource}.test.delete" || _return_code=$?
    if [[ $_return_code != 0 ]]; then
      array.push _post_delete_failures $_resource
      _failure_happened=1
    fi

    _post_delete_changes=$waffles_total_changes

    if [[ $_post_delete_changes -gt $_delete_changes ]]; then
      log.error "Changes happened on the system"
      array.push _post_delete_failures $_resource
      _failure_happened=1
    fi
  fi

  if [[ -n $_failure_happened ]]; then
    _test_failure=1
  fi

  log.info "Running teardown"
  "${_resource}.test.teardown" || {
    log.error "Unable to teardown tests for $_resource. Cannot proceed."
    _teardown_failure=$_resource
    break
  }
done

log.info "Test Results"

if [[ $(array.length _create_failures) -gt 0 ]]; then
  log.error "Create Failures in:"
  for _r in "${_create_failures[@]}"; do
    log.error "    $_r"
  done
fi

if [[ $(array.length _post_create_failures) -gt 0 ]]; then
  log.error "Post Create Failures in:"
  for _r in "${_post_create_failures[@]}"; do
    log.error "    $_r"
  done
fi

if [[ $(array.length _update_failures) -gt 0 ]]; then
  log.error "Update Failures in:"
  for _r in "${_update_failures[@]}"; do
    log.error "    $_r"
  done
fi

if [[ $(array.length _post_update_failures) -gt 0 ]]; then
  log.error "Post Update Failures in:"
  for _r in "${_post_update_failures[@]}"; do
    log.error "    $_r"
  done
fi

if [[ $(array.length _delete_failures) -gt 0 ]]; then
  log.error "Delete Failures in:"
  for _r in "${_delete_failures[@]}"; do
    log.error "    $_r"
  done
fi

if [[ $(array.length _post_delete_failures) -gt 0 ]]; then
  log.error "Post Delete Failures in:"
  for _r in "${_post_delete[@]}"; do
    log.error "    $_r"
  done
fi

if [[ -n $_setup_failure ]]; then
  log.error "A setup error happened with $_setup_failure."
  exit 1
fi

if [[ -n $_teardown_failure ]]; then
  log.error "A setup error happened with $_teardown_failure."
  exit 1
fi

if [[ -n $_test_failure ]]; then
  exit 1
fi

exit 0

log.info "symlink"
os.file --name /usr/local/bin/foo
os.symlink --name /usr/bin/foo --target /usr/local/bin/foo

log.info "symlink removal"
touch /usr/local/bin/foo2
if [[ -z $BUSSER_ROOT ]]; then
  ln -s /usr/local/bin/foo2 /usr/bin/foo2
fi
os.symlink --state absent --name /usr/bin/foo2

log.info "symlink overwrite"
touch /usr/local/bin/foo3
touch /usr/local/bin/foo4
if [[ -z $BUSSER_ROOT ]]; then
  ln -s /usr/local/bin/foo3 /usr/bin/foo3
fi
os.symlink --name /usr/bin/foo3 --target /usr/local/bin/foo4 --overwrite true

log.info "ruby gems"
apt.pkg --package ruby1.9.1
ruby.gem --name thor --version 0.19.0

if [[ -n $BUSSER_ROOT ]]; then
  if [[ $waffles_total_changes -gt 0 ]]; then
    log.error "Changes happened on the system."
    exit 1
  fi
fi
