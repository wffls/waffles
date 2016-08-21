service.sysv.test.setup() {
  apt.pkg --name memcached
}

service.sysv.test.create() {
  service.sysv --name memcached --state running
}

service.sysv.test.update() {
  return
}

service.sysv.test.delete() {
  service.sysv --name memcached --state stopped
}

service.sysv.test.teardown() {
  apt.pkg --name memcached --state absent
}
