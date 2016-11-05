#!/bin/bash
set -eu
source /opt/waffles/init.sh
source /etc/lsb-release

WAFFLES_DEBUG=1

declare _return_code=0

if [[ ! -f /tmp/waffles_resource.txt ]]; then
  log.error "/tmp/waffles_resource.txt must contain a resource to test."
  exit 1
fi

declare _resource="$(cat /tmp/waffles_resource.txt)"
declare _resource_test_path="/opt/waffles/tests/kitchen/test/resources/${_resource}"

if [[ ! -f $_resource_test_path ]]; then
  log.error "Test file for ${_resource} not found. It needs to be in ${_resource_test_path}."
  exit 1
fi

source $_resource_test_path

log.info "Running CRUD tests for $_resource"

log.info "Running setup"
setup || {
  log.error "Unable to setup test for $_resource. Cannot proceed."
  exit 1
}

log.info "Verifying dependencies exist for $_resource"
$_resource 2>/dev/null || _return_code=$?
if [[ $_return_code == 2 ]]; then
  log.error "Missing dependencies for $_resource."
  exit 1
fi

log.info "Running create test"
create || {
  log.error "Create test failed."
  exit 1
}

_create_changes=$waffles_total_changes

log.info "Verifying resources were successfully created"
create || {
  log.error "Second run of create failed."
  exit 1
}

_post_create_changes=$waffles_total_changes

if [[ $_post_create_changes -gt $_create_changes ]]; then
  log.error "Changes happened on the system."
  exit 1
fi

log.info "Running update tests"
update || {
  log.error "Update test failed."
  exit 1
}

_update_changes=$waffles_total_changes

log.info "Verifying resources were successfully updated."
update || {
  log.error "Second run of update failed."
  exit 1
}

_post_update_changes=$waffles_total_changes

if [[ $_post_update_changes -gt $_update_changes ]]; then
  log.error "Changes happened on the system."
  exit 1
fi

log.info "Running delete test."
delete || {
  log.error "Delete test failed."
  exit 1
}

_delete_changes=$waffles_total_changes

log.info "Verifying resources were successfully deleted."
delete || {
  log.error "Second run of delete failed."
  exit 1
}

_post_delete_changes=$waffles_total_changes

if [[ $_post_delete_changes -gt $_delete_changes ]]; then
  log.error "Changes happened on the system"
  exit 1
fi

log.info "Running teardown"
teardown || {
  log.error "Unable to teardown test for $_resource."
  exit 1
}
