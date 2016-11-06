setup() {
  apt.pkg --name software-properties-common
}

create() {
  apt.ppa --ppa chris-lea/redis-server
}

update() {
  return
}

delete() {
  apt.ppa --ppa chris-lea/redis-server --state absent
}

teardown() {
  apt.pkg --name software-properties-common --state absent
}
