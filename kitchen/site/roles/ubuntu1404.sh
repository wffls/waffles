source /etc/lsb-release

log.info "groupadd"
os.groupadd --group memcache --gid 999

log.info "useradd"
os.useradd --user memcache --gid 999 --uid 999 --homedir /var/lib/memcached

log.info "foobar"
os.useradd --user foobar --system true

log.info "packages"
apt.pkg --package memcached
apt.pkg --package cron

log.info "apt-key and apt-source"
apt.key --name rabbitmq --key 056E8E56 --remote_keyfile https://www.rabbitmq.com/rabbitmq-signing-key-public.asc
apt.source --name rabbitmq --uri http://www.rabbitmq.com/debian/ --distribution testing --component main --include_src false

apt.key --name percona --keyserver keys.gnupg.net --key 1C4CBDCDCD2EFD2A
apt.source --name percona --uri http://repo.percona.com/apt --distribution $DISTRIB_CODENAME --component main --include_src true

log.info "cron"
cron.entry --name foobar --cmd ls --minute "*/5" --hour 4

log.info "directory"
os.directory --name /opt/puppetlabs/agent/facts.d --parent true

log.info "file"
os.file --name /opt/puppetlabs/agent/facts.d/role.txt --content "role=memcache"

log.info "file.line"
file.line --file /etc/memcached.conf --line "-m 128" --match "^-m"

log.info "ini"
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
