setup() {
  apt.pkg --name memcached
}

create() {
  service.sysv --name memcached --state running
}

update() {
  return
}

delete() {
  service.sysv --name memcached --state stopped
}

teardown() {
  apt.pkg --name memcached --state absent
}
