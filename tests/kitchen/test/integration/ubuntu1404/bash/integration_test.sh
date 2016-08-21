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

for t in /root/.waffles/resources/tests/*.sh; do
  source $t

  _resource=$(basename $t | sed -e 's/_test.sh//g' -e 's/_/./g')
  log.info "Running CRUD tests for $_resource"

  log.info "Running create tests"
  create
  _create_changes=$waffles_total_changes

  log.info "Verifying resources were successfully created"
  create
  _post_create_changes=$waffles_total_changes

  if [[ $_post_create_changes -gt $_create_changes ]]; then
    log.error "Changes happened on the system"
    exit 1
  fi

  log.info "Running update tests"
  update
  _update_changes=$waffles_total_changes

  log.info "Verifying resources were successfully updated"
  update
  _post_update_changes=$waffles_total_changes

  if [[ $_post_update_changes -gt $_update_changes ]]; then
    log.error "Changes happened on the system"
    exit 1
  fi

  log.info "Running delete tests"
  delete
  _delete_changes=$waffles_total_changes

  log.info "Verifying resources were successfully deleted"
  delete
  _post_delete_changes=$waffles_total_changes

  if [[ $_post_delete_changes -gt $_delete_changes ]]; then
    log.error "Changes happened on the system"
    exit 1
  fi
done

exit 0

log.info "packages"
apt.pkg --package memcached
apt.pkg --name cron
apt.pkg --name sl

log.info "directory"
if [[ -z ${BUSSER_ROOT:-} ]]; then
  mkdir /opt/foo
  chmod 0700 /opt/foo
fi
os.directory --name /opt/foo --mode 0755

log.info "apt-key and apt-source"
apt.key --name rabbitmq --key 056E8E56 --remote_keyfile https://www.rabbitmq.com/rabbitmq-signing-key-public.asc
apt.source --name rabbitmq --uri http://www.rabbitmq.com/debian/ --distribution testing --component main --include_src false

apt.key --name percona --keyserver keys.gnupg.net --key 1C4CBDCDCD2EFD2A
apt.source --name percona --uri http://repo.percona.com/apt --distribution $DISTRIB_CODENAME --component main --include_src true

log.info "cron"
cron.entry --name foobar --cmd ls --minute "*/5" --hour 4

log.info "file"
os.file --name /opt/puppetlabs/agent/facts.d/role.txt --content "role=memcache"

log.info "file.line"
file.line --file /etc/memcached.conf --line "-m 128" --match "^-m"

log.info "ini"
os.file --name /root/test.ini
file.ini --file /root/test.ini --section foobar --option foo --value bar
file.ini --file /root/test.ini --section foobar --option baz --value __none__

log.info "sysv"
service.sysv --name memcached

log.info "git"
apt.pkg --package git
git.repo --name /root/.dotfiles --source https://github.com/jtopjian/dotfiles

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
