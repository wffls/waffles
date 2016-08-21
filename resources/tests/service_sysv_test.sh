create() {
  apt.pkg --name memcached
  service.sysv --name memcached --state running
}

update() {
  service.sysv --name memcached --state stopped
}

delete() {
  apt.pkg --name memcached --state absent
}
